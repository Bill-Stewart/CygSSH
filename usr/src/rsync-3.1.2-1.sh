#!/bin/bash
#
#   cygbuild.sh -- A generic Cygwin Net Release package builder script
#
#       Copyright (C) 2003-2015 Jari Aalto
#
#   License
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   WARNING
#
#       If the name of this file is not "cygbuild" or "cygbuild.sh",
#       then it has been auto-generated and you are looking at the
#       result of packaging script.
#
#       IN THAT CASE YOU SHOULD NOT TRY TO USE THIS PROGRAM FOR
#       ANYTHING ELSE THAN CALLING PROGRAM WITH ONE OF THESE COMMANDS:
#
#           all
#           almostall
#
#       Notes
#
#       o   Option -h for quick help, -c for color, -v for verbose
#       o   Global variables ARE_LIKE_THIS and local variables are areLikeThis
#       o   GNU programs are required. grep(1), egrep(1), awk(1) etc.
#
#   Other notes
#
#       o   cygcheck is a MingW applications outputs have CRLF line endings

CYGBUILD_HOMEPAGE_URL="https://github.com/jaalto/project--cygwin-cygbuild"
CYGBUILD_AUTHOR="Jari Aalto"
CYGBUILD_LICENSE="GPL-2+"
CYGBUILD_NAME="cygbuild"

#  Automatically updated by the developer's editor on save

CYGBUILD_VERSION="2015.0926.1623"

#  Used by the 'cygsrc' command to download official Cygwin packages
#  listed at http://cygwin.com/packages

CYGBUILD_SRCPKG_URL=${CYGBUILD_SRCPKG_URL:-\
"http://gd.tuwien.ac.at/gnu/cygwin"}
# {x86,x86_64}/setup.ini
# "http://ftp.inf.tu-dresden.de/software/windows/cygwin"}

CYGBUILD_INSTALL_INFO="\
    git clone git://git.savannah.nongnu.org/cygbuild.git
    cd cygbuild
    git checkout --track -b devel origin/devel
    make install-symlink"

#######################################################################
#
#       Initial shell check
#
#######################################################################

#   Check correct shell and detect user mistakes like this:
#
#       sh ./program.sh
#
#   The following will succeed under bash, but will give error under sh
#
#   NOTE: In some places the sh is copy of bash (or symlink), but bash
#   would still restrict it to certain features. The simplistic test
#   is not enough. See bash manual and section "INVOCATION".
#
#       eval "[[ 1 ]]" > /dev/null
#
#   The process substitution test will fail under Bash running as
#   "sh" mode.
#
#    eval ": <(:)" > /dev/null

[ "$BASH" = "/usr/bin/bash" ] || [ "$BASH" = "/bin/bash" ] ||
{
    prg="$0"

    # If we did not find ourselves, most probably we were run as
    # 'sh PROGRAM' in which case we are not to be found in PATH.

    if [ -f "$prg" ]; then
        [ -x /bin/bash ] && exec /bin/bash "$prg" ${1:+"$@"}
    fi

    echo "$0 [FATAL] $prg called with wrong shell: needs bash" >&2
    exit 1 ;
}

shopt -s extglob    # Use extra pattern matching options
set -o pipefail     # status comes from the failed pipe command

LC_ALL=C            # So that sort etc. works as expected.
LANG=C              # Display errors in plain English

# Use clean PATH

PATH="/usr/bin:/usr/lib:/usr/sbin:/bin:/sbin:$PATH"

# Cancel any environment settings

for tmp in \
    awk \
    egrep \
    gcc \
    grep \
    head \
    make \
    patch \
    perl \
    quilt \
    sed \
    tail \
    tar \
    wget
do
    unset -f $tmp
    unalias $tmp 2> /dev/null
done

unset tmp

#######################################################################
#
#       Primitives
#
#######################################################################

function CygbuildAskYes()
{
    echo "$* (y/N) "
    read

    [[ "$REPLY" == [yY]* ]]
}

function CygbuildPushd()
{
    pushd . > /dev/null
}

function CygbuildPopd()
{
    popd > /dev/null
}

function CygbuildWhich()
{
    # Returns path name.
    #
    # Do NOT use which(1) under Cygwin. It does not find programs that
    # are symlinks

    [ "$1" ] && type -p "$1" 2> /dev/null
}

function CygbuildWhichCheck()
{
    # Ignore return value; the path name itself.
    # We're interested in status code only for the caller.

    [ "$1" ] && CygbuildWhich "$1" > /dev/null
}

function CygbuildRun()
{
    ${test:+echo} "$@"
}

function CygbuildRunIfExist()
{
    [ "$1" ] && CygbuildWhichCheck "$1" && "$@"
}

function CygbuildDate()
{
    date "+%Y%m%d%H%M"
}

function CygbuildStripCR ()
{
    sed -e "s,\r,,"
}

function CygbuildPathBinFast()
{
    #   ARG 1: binary name
    #   ARG 2: possible additional search path like /usr/local/bin

    local bin="$1"
    local try="${2%/}"      # Delete trailing slash

    #   If it's not in these directories, then just use
    #   plain "cmd" and let bash search whole PATH

    if [ -x /usr/bin/$bin ]; then
        echo /usr/bin/$bin

    elif [ -x /bin/$bin ]; then
        echo /bin/$bin

    elif [ -x /usr/sbin/$bin ]; then
        echo /usr/sbin/$bin

    elif [ -x /sbin/$bin ]; then
        echo /sbin/$bin

    elif [ "$try" ] && [ -x $try/$bin ]; then
        echo $try/$bin

    else
        return 1
    fi
}

function CygbuildTarOptionCompress()
{
    local id="$0.$FUNCNAME"

    #   Return correct packaging command based on the filename
    #   .tar.gz or .tgz     => "z" option
    #   .bz2                => "j" option

    case "$1" in
        *.tar.gz | *.tgz)
            echo "--gzip"
            ;;
        *.bz2 | *.tbz*)
            echo "--bzip2"
            ;;
        *.lzma)
            echo "--use-compress-program=lzma"
            ;;
        *.xz)
            echo "--use-compress-program=xz"
            ;;
        *)  return 1
            ;;
    esac
}

function CygbuildStrToRegexpSafe()
{
    # Just a quick conversion

    local str="$1"

    [ "$str" ] || return 1

    str=${str//\[/\\[}
    str=${str//\]/\\]}

    str=${str//./[.]}
    str=${str//+/[+]}
    str=${str//\*/[*]}
    str=${str//\?/[?]}

    str=${str//\(/[(]}
    str=${str//\)/[)]}

    echo "$str"
}

function CygbuildMatchGlob()
{
    case "$2" in
        $1) return 0
            ;;
        *)  return 1
            ;;
    esac
}

function CygbuildMatchRegexp()
{
    #   Argument 1: regexp
    #   Argument 2: string to match

    if [[ ${BASH_VERSINFO[0]} == 3 ]]; then
        [[ $2 =~ $1 ]]
    else
        echo "$2" | $EGREP --quiet "$1"
    fi
}

function CygbuildMatchPatternRemoveWord()
{
    # ARG 1: pattern to match removed words
    # ARG 2: list of words

    local pattern="$1"
    shift

    local item new

    for item in "$@"
    do
        [[ "$item" == $pattern ]] && continue

        new="$new $item"
    done

    echo $new
}

function CygbuildMatchPatternList()
{
    # ARG 1: STRING to match
    # ARG 2..: List of glob patterns to match against STRING

    local str="$1"

    [ ! "$str" ] && return 1

    shift

    #   In for loop, the patterns in $list
    #   would expand to file names without 'noglob'.

#    set -o noglob

    local ret=1    # Suppose no match by default
    local match

    for match in "$@"
    do
        if [[ "$str" == $match ]]; then
            ret=0
            break
        fi
    done

#   set +o noglob

    return $ret
}

function CygbuildIsEmpty()
{
    [ ! "$1" ] || CygbuildMatchRegexp '^[ \t]*$' "$1"
}

function CygbuildIsNumber()
{
    CygbuildMatchRegexp '^[0-9]+$' "$1"
}

function CygbuildIsNumberLike()
{
    CygbuildMatchRegexp '[0-9]' "$1"
}

function CygbuildIsCygwin()
{
    # The value of MACHTYPE or ...

    [[ "${BASH_VERSINFO[5]}" == *cygwin* ]] ||
    [ -d /cygdrive/c ]
}

function CygbuildIsLinux()
{
    [ -d /boot/vmlinuz ]
}

#######################################################################
#
#       Primitives 2
#
#######################################################################

function CygbuildIsSourceProgram ()
{
    # Check "the packaging script" foo-N.N.sh

    [[ $0 == *-[0-9]* ]]
}

function CygbuildIsSourceUnpacked ()
{
    [ -f "$DIR_CYGPATCH/$PKG.README" ]
}

function CygbuildIsGbsCompat()
{
    [ "$OPTION_GBS_COMPAT" ] || CygbuildIsSourceProgram
}

#######################################################################
#
#       Error functions
#
#######################################################################

function CygbuildMsgFilter()
{
    if [ ! "$OPTION_COLOR" ] || [ ! "$PERLBIN" ] || [ ! -f "$PERLBIN" ]
    then
        cat                                             # Pass through
        return 0
    fi

    local topic="$CYGBUILD_COLOR_BLACK1"
    local error="$CYGBUILD_COLOR_RED1"
    local fatal="$CYGBUILD_COLOR_RED1R"
    local warn="$CYGBUILD_COLOR_RED"
    local info="$CYGBUILD_COLOR_PURPLE"
    local msg="$CYGBUILD_COLOR_BLUE"
    local em="$CYGBUILD_COLOR_BLUE1"
    local note="$CYGBUILD_COLOR_BLUEU"
    local external="$CYGBUILD_COLOR_PINK"
    local end="$CYGBUILD_COLOR_RESET"

    export topic error error fatal warn info msg note external end

    local str=$(
        $PERLBIN -ane '
            exit 0 unless /\S/;

            eval "\$$_ = q($ENV{$_});" for
              qw(topic error error fatal warn info
                 msg note external end);

            $e = $end;

            s,^(==.*),$topic$1$e, ;
            s,(.*ERROR.*),$error$1$e, ;
            s,(.*FATAL.*),$fatal$1$e, ;
            s,(.*WARN.*),$warn$1$e, ;
            s,(.*(?:INFO|NOTE).*),$info$1$e, ;
            s,^(>>.*),$external$1$e, ;
            s,^--- ([^[].*?:)(.*),-- $note$1$msg$2$e, ;

            s{^(-- [^[].+ \s+ < \s+)
                (\S+/\S+) \s* $
             }
             {$msg$1$external$2$e}x    or
            s,^(-- [^[].*),$msg$1$e, ;

            print;
    ')

    if [ "$str" ]; then
        echo -e "$str"
    fi
}

function CygbuildEcho()
{
    if [ "$OPTION_COLOR" ]; then
        echo -e "$*" | CygbuildMsgFilter
    else
        echo -e "$*"
    fi
}

function CygbuildVerb()
{
    if [ "$verbose" ] && [ "$1" ]; then
        CygbuildEcho "$*"
    fi
}

function CygbuildWarn()
{
    CygbuildEcho "$*" >&2
}

function CygbuildVerbWarn()
{
    if [ "$verbose" ] ; then
        CygbuildWarn "$*"
    fi
}

function CygbuildExit()
{
    # ARG 1: optional, exit code
    # ARG 2: optional, message

    local code=${1:-1}
    shift

    if [ "$1" ]; then
        CygbuildWarn "$*"
    fi

    exit $code
}

function CygbuildDie()
{
    CygbuildExit 1 "$@"
}

function CygbuildExitIfNoDir()
{
    local dir="$1"
    shift

    if [ ! "$dir" ] || [ ! -d "$dir" ]; then
        CygbuildDie "$@"
    fi
}

function CygbuildExitIfNoFile()
{
    local file="$1"
    shift

    if [ ! "$file" ] || [ ! -f "$file" ]; then
        CygbuildDie "$@"
    fi
}

function CygbuildExitIfEmpty()
{
    if [ ! "$1" ]; then
        shift
        CygbuildDie "$@"
    fi
}

#######################################################################
#
#       VARIABLES
#
#######################################################################

function CygbuildBootVariablesId()
{
    #   Public ENVIRONMENT VARIABLES: User settings

    #   These variables are used only when command [publish] is run.
    #   The ready bin and source packages are either:
    #
    #   1) passed to script (or bash function) $CYGBUILD_PUBLISH_BIN
    #   2) or copied into separate subdirectory pointed by
    #      $CYGBUILD_PUBLISH_DIR. Separate subdirectories are created for
    #      each published package before copying files.

    CYGBUILD_PUBLISH_BIN=${CYGBUILD_PUBLISH_BIN:-""}        # global-def
    CYGBUILD_PUBLISH_DIR=${CYGBUILD_PUBLISH_DIR:-"/usr/src/cygwin-packages"} # global-def

    TEMPDIR=${TEMPDIR:-${TEMP:-${TMP:-/tmp}}}               # global-def
    TEMPDIR=${TEMPDIR%/}  # Remove trailing slash

    #   Private: program startup and name

    CYGBUILD_PROGRAM="Cygbuild $CYGBUILD_VERSION"           # global-def
    CYGBUILD_DIR_CYGPATCH_RELATIVE="CYGWIN-PATCHES"         # global-def

    #  Function return values are stored to files, because bash cannot call
    #  function with parameters in running shell environment. The only way to
    #  call bash function and collect its value would:
    #
    #       local val=$(FunctionName "param")
    #
    #  But because this is a subshell call, any variables defined globally
    #  ina "func" would vanish after 'func' finishes. This is also slow.
    #
    #  To call a function, which sets global variables, it must be done like
    #  this. The return value is stored to file and the result is then read.
    #  The return value file must be made unique to each function with
    #  bash $FUNCNAME variable.
    #
    #       local retval=$RETVAL.$FUNCNAME
    #       FunctionName "param" > $retval
    #       local val=$(< $retval)

    CYGBUILD_RETVAL="$TEMPDIR/$CYGBUILD_NAME.tmp.${LOGNAME:-$USER}.$$" # global-def
    local retval="$CYGBUILD_RETVAL"

    CYGBUILD_PROG_NAME=${0##*/}                             # global-def

    if [[ "$0" == */* ]]; then
        CYGBUILD_PROG_PATH=$(cd "${0%/*}" && pwd)             # global-def
    else
        CygbuildWhich "$CYGBUILD_PROG_NAME" > $retval
        CYGBUILD_PROG_PATH=$(< $retval)
    fi

    local path="$CYGBUILD_PROG_PATH"

    #   Depends how program is installed.

    CYGBUILD_PROG_LIBPATH=                                  # global-def

    if [[ "$CYGBUILD_PROG_NAME" == *-[0-9].sh ]]    # GBS: foo-N.N-1.sh
    then

        #   Secondary
        [ -d /usr/share/cygbuild ] &&
        CYGBUILD_PROG_LIBPATH=/usr/share/cygbuild

        #   Primary
        [ -d /usr/local/share/cygbuild ] &&
        CYGBUILD_PROG_LIBPATH=/usr/local/share/cygbuild

    elif [[ "$path" == /usr/local* ]]; then
        CYGBUILD_PROG_LIBPATH=/usr/local/share/cygbuild
    elif [[ "$path" == /usr/bin* ]]; then
        CYGBUILD_PROG_LIBPATH=/usr/share/cygbuild
    fi

    CYGBUILD_PRG_FULLPATH="$CYGBUILD_PROG_PATH/$CYGBUILD_PROG_NAME"
}

function CygbuildDefineGlobalPerlVersion()
{
    # This is perl 5, version 14, subversion 2 (v5.14.2)

    PERL_VERSION=$(                                 # global-def
        perl --version |
        awk '
            /This is perl/  &&  $4 ~ /[0-9]\.[0-9]/ {
                ver = $4
                sub("v", "", ver)
                print ver
                exit 0
            }
            /This is perl/  &&  $9 ~ /v[0-9]+\.[0-9]/ {
                ver = $9
                gsub("[v()]", "", ver)
                print ver
                exit 0
            }
        '
    )

    if [ ! "$PERL_VERSION" ]; then
        CygbuildWarn "-- [WARN] Internal error, cannot read PERL_VERSION"
        return 1
    fi
}

function CygbuildDefineGlobalPythonVersion()
{
    PYTHON_VERSION=$(                               # global-def
        python -V 2>&1 |
        awk '{print $2}'
    )

    if [[ "$PYTHON_VERSION" == *.*.* ]]; then
        # N.N.N => N.N
        PYTHON_VERSION_MAJOR=${PYTHON_VERSION%.*}   # global-def

    elif [[ "$PYTHON_VERSION" == *.* ]]; then
        PYTHON_VERSION_MAJOR=$PYTHON_VERSION}       # global-def
    fi

    [ "$PYTHON_VERSION" ]
}

function CygbuildDefineGlobalRubyVersion()
{
    #  ruby 1.8.7 (2009-06-12 patchlevel 174)

    RUBY_VERSION=$(                               # global-def
        ruby --version 2>&1 |
        awk '{print $1}'
    )

    [ "$RUBY_VERSION" ]
}

function CygbuildBootVariablesCache()
{
    #   Private: CACHE VARIABLES; remember last function call values

    # path to module cygbuild.pl
    declare -a CYGBUILD_STATIC_PERL_MODULE
    declare -a CYGBUILD_STATIC_ABSOLUTE_SCRIPT_PATH  # (bin path)

    declare -a CYGBUILD_STATIC_VER_ARRAY             # (pkg ver release)
    declare CYGBUILD_STATIC_VER_PACKAGE=""
    declare CYGBUILD_STATIC_VER_VERSION=""
    declare CYGBUILD_STATIC_VER_RELEASE=""
    declare CYGBUILD_STATIC_VER_STRING=""
}

function CygbuildBootVariablesGlobalEtcSet()
{
    local dir="$1"

    CYGBUILD_ETC_DIR="$dir"                                     #global-def
    CYGBUILD_TEMPLATE_DIR_USER="$CYGBUILD_ETC_DIR/template"     #global-def
    CYGBUILD_CONFIG_MAIN="$CYGBUILD_ETC_DIR/cygbuild.conf"      #global-def
}

function CygbuildBootVariablesGlobalEtcMain()
{
    local id="$0.$FUNCNAME"
    local dir=/etc/cygbuild

    if [ -d "$dir" ]; then
        CygbuildBootVariablesGlobalEtcSet $dir
        return 0
    fi

    #   from current location?

    local tmp="$CYGBUILD_PROG_PATH"

    [ "$tmp" ]    || CygbuildDie "[FATAL] $id: a:No directory found at $dir"
    [ -d "$tmp" ] || CygbuildDie "[FATAL] $id: b:No directory found at $tmp"

    #  This is the source archive structure
    #
    #  ROOT
    #  |
    #  +-bin/
    #  +-etc/template/

    tmp=${tmp%/*}  # One directory up (from bin/)
    tmp="$tmp/etc/etc"

    if [ -d "$tmp" ]; then
        CygbuildBootVariablesGlobalEtcSet "$tmp"
    elif CygbuildIsGbsCompat ; then
        #  Ignore. The cygbuild full suite is not installed
        :
    else
        #  This is fatal only when trying to build sources
        CygbuildDie "[FATAL] $id: No ETC directory found"
    fi
}

function CygbuildBootVariablesGlobalShareSet()
{
    local dir="$1"

    CYGBUILD_SHARE_DIR="$dir"                                   #global-def
    CYGBUILD_TEMPLATE_DIR_MAIN="$CYGBUILD_SHARE_DIR/template"   #global-def
}

function CygbuildBootVariablesGlobalCacheGenerate()
{
    local package="$1"
    local file="$2"

    if [ ! "$CYGCHECK" ]; then
        CygbuildWarn "-- [WARN] cygcheck(1) not in PATH." \
                     "Cannot make cache: $package"
        return 1
    fi

    $CYGCHECK -l $package | ${PERLBIN:-perl} -pe 's,\r,,' > "$file"

    [ -s "$file" ]
}

function CygbuildBootVariablesGlobalCachePerlGenerate()
{
    [ "$PERL_VERSION" ] || return 1

    local dir="$CYGBUILD_PROG_LIBPATH"
    local file="$dir/perl-${PERL_VERSION}.lst"

    CygbuildBootVariablesGlobalCacheGenerate perl "$file"
}

function CygbuildBootVariablesGlobalCachePerl()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    [ "$PERL_VERSION" ] || CygbuildDefineGlobalPerlVersion || return 1

    #   Set Perl package content cache. This is needed to check if
    #   modules are Standard perl or from CPAN.

    local file="$dir/perl-${PERL_VERSION}.lst"
    CYGBUILD_CACHE_PERL_FILES=                                  # global-def

    if [ -s "$file" ]; then
        CYGBUILD_CACHE_PERL_FILES="$file"                       # global-def
    else
        CygbuildVerb "-- [WARN] No Perl cache available: $file"
    fi
}

function CygbuildBootVariablesGlobalCachePythonGenerate()
{
    [ "$PYTHON_VERSION" ] || return 1

    local dir="$CYGBUILD_PROG_LIBPATH"
    local file="$dir/perl-${PYTHON_VERSION}.lst"

    CygbuildBootVariablesGlobalCacheGenerate python "$file"
}

function CygbuildBootVariablesGlobalCachePython()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    [ "$PYTHON_VERSION" ] || CygbuildDefineGlobalPythonVersion || return 1

    local file="$dir/python-${PYTHON_VERSION}.lst"
    CYGBUILD_CACHE_PYTHON_FILES=                                # global-def

    if [ -s "$file" ]; then
        CYGBUILD_CACHE_PYTHON_FILES="$file"                     # global-def
    else
        CygbuildVerb "-- [WARN] No Python cache available: $file"
    fi
}

function CygbuildBootVariablesGlobalCacheRubyGenerate()
{
    [ "$RUBY_VERSION" ] || return 1

    local dir="$CYGBUILD_PROG_LIBPATH"
    local file="$dir/perl-${RUBY_VERSION}.lst"

    CygbuildBootVariablesGlobalCacheGenerate perl "$file"
}

function CygbuildBootVariablesGlobalCacheRuby()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    [ "$RUBY_VERSION" ] || CygbuildDefineGlobalRubyVersion || return 1

    #   Set package content cache. This is needed to check if
    #   modules are Standard Ruby

    local file="$dir/perl-${RUBY_VERSION}.lst"
    CYGBUILD_CACHE_RUBY_FILES=                                  # global-def

    if [ -s "$file" ]; then
        CYGBUILD_CACHE_RUBY_FILES="$file"                       # global-def
    else
        CygbuildVerb "-- [WARN] No Ruby cache available: $file"
    fi
}

function CygbuildBootVariablesGlobalCacheSet()
{
    CygbuildBootVariablesGlobalCachePerl   "$1"
    CygbuildBootVariablesGlobalCachePython "$1"
    CygbuildBootVariablesGlobalCacheRuby   "$1"
}

function CygbuildBootVariablesGlobalLibSet()
{
    local dir="$1"

    CYGBUILD_PERL_MODULE_NAME="cygbuild.pl"                     #global-def
    local tmp="$dir/$CYGBUILD_PERL_MODULE_NAME"                 #global-def

    if [ -f "$tmp" ]; then
        CYGBUILD_STATIC_PERL_MODULE="$tmp"                      #global-def
    else
        CygbuildVerb "-- [WARN] Not found $tmp"
    fi
}

function CygbuildBootVariablesGlobalShareDir()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    CygbuildExitIfNoDir "$dir" \
        CygbuildDie "$id: [ERROR] Internal error. No DIR argument"

    CygbuildBootVariablesGlobalShareSet "$dir"
    CygbuildBootVariablesGlobalCacheSet "$dir/data"
    CygbuildBootVariablesGlobalLibSet   "$dir/lib"
}

function CygbuildBootVariablesGlobalShareMain()
{
    local id="$0.$FUNCNAME"
    local dir="$CYGBUILD_PROG_LIBPATH"

    if [ "$dir" ] && [ -d "$dir" ]; then
        CygbuildBootVariablesGlobalShareDir "$dir"
        return 0
    fi

    #   Not installed site wide but probably run-in-place. Determine
    #   paths relative to the program location.

    local tmp="$CYGBUILD_PROG_PATH"

    [ "$tmp" ]    || CygbuildDie "[FATAL] $id: a:No directory found at $dir"
    [ -d "$tmp" ] || CygbuildDie "[FATAL] $id: b:No directory found at $tmp"

    tmp=${tmp%/*}  # One directory up (from bin/)
    dir="$tmp/etc/template"

    [ -d "$tmp" ] || CygbuildDie "[FATAL] $id: c:No directory found at $tmp"

    dir="$tmp/etc"

    CygbuildBootVariablesGlobalShareDir "$dir"
}

function CygbuildBootVariablesGlobalCacheMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.cache"
    local path=$CYGBUILD_PROG_PATH
    local dir=/var/cache/cygbuild

    CYGBUILD_CACHE_DIR="$dir"                                   #global-def
}

function CygbuildBootVariablesGlobalColors()
{
    CYGBUILD_COLOR_BLACK="\033[00;30m"    # basic
    CYGBUILD_COLOR_BLACK1="\033[01;30m"   # bold
    CYGBUILD_COLOR_BLACKR="\033[07;30m"   # reverse
    CYGBUILD_COLOR_RED="\033[00;31m"
    CYGBUILD_COLOR_RED1="\033[01;31m"
    CYGBUILD_COLOR_RED1U="\033[04;31m"    # underline
    CYGBUILD_COLOR_RED1R="\033[07;31m"    # reverse
    CYGBUILD_COLOR_GREEN="\033[00;32m"    # not readable in cygwin rxvt
    CYGBUILD_COLOR_GREEN1="\033[01;32m"   # not readable in cygwin rxvt
    CYGBUILD_COLOR_BROWN="\033[00;33m"    # barely readable in cygwin rxvt
    CYGBUILD_COLOR_YELLOW="\033[01;33m"   # not readable in cygwin rxvt
    CYGBUILD_COLOR_BLUE="\033[00;34m"
    CYGBUILD_COLOR_BLUEU="\033[04;34m"    # underline
    CYGBUILD_COLOR_BLUER="\033[07;34m"    # reverse
    CYGBUILD_COLOR_BLUE1="\033[01;34m"
    CYGBUILD_COLOR_PURPLE="\033[00;35m"
    CYGBUILD_COLOR_PINK="\033[01;35m"
    CYGBUILD_COLOR_PINKU="\033[04;35m"    # underline
    CYGBUILD_COLOR_PINK2="\033[05;35m"    #
    CYGBUILD_COLOR_PINKR="\033[07;35m"    # reverse
    CYGBUILD_COLOR_CYAN="\033[00;36m"     # not readable in cygwin rxvt
    CYGBUILD_COLOR_CYAN1="\033[01;36m"    # not readable in cygwin rxvt
    CYGBUILD_COLOR_GRAY="\033[00;37m"     # not readable in cygwin rxvt
    CYGBUILD_COLOR_WHITE="\033[01;37m"    # not readable in cygwin rxvt

    CYGBUILD_COLOR_RESET="\033[00m"       # reset to teminal default
}

function CygbuildBootVariablesGlobalMain()
{
    #  Like: <file>.$CYGBUILD_SIGN_EXT
    CYGBUILD_GPG_SIGN_EXT=.sig

    #       Private: install options and other variables

    #  This variable holds bash match expressions for files to exclude
    #  from original sources while copying the user documentation to
    #  /usr/share/Cygwin/<package-version>
    #
    #  E.g. BCC_MAKEFILE, WCC_MAKEFILE, Makefile.am ... => drop
    #
    #  Note: This variable lists bash '==' pattern tests to exlude
    #  files that contain BIG letters. See separate tar exclude
    #  variable for all other files.

    CYGBUILD_INSTALL_IGNORE=" \
    *Makefile* *makefile* *MAKEFILE* \
    *CVS \
    *RCS \
    *MT \
    *.bak \
    *.BAK \
    *.ex \
    *.in \
    *.orig \
    *.rej \
    *.tmp \
    *.TMP \
    *.TST \
    *.spec \
    *ABOUT-NLS \
    *CHANGES-* \
    *INSTALL* \
    *MANIFEST* \
    *PACKAGE \
    *README.*bsd* \
    *README.OS2 \
    *README.hp* \
    *README.mingw32 \
    *README.vms \
    *README.DOS \
    *RISC-* \
    *VERSION \
    *VMS* \
    *[~#] \
    "

    #  This variable holds bash match expressions for files to exclude
    #  check of zero length files. The expression may contain patch
    #  componen match of the file. Files are find(1) collected under
    #  install directory.

    CYGBUILD_IGNORE_ZERO_LENGTH="*@(__init__.py)"

    #   This is egrep(1) match for files found in toplevel. Case sensitive.

    CYGBUILD_SHADOW_TOPLEVEL_IGNORE="\
[.](build|s?inst|tmp)\
|(CVS|RCS|MT|[.](svn|bzr|hg|git|darcs))$\
|[.]([oa]|exe|la|dll)$\
|[.]#\
|[#~]$\
"

    #   Accept X11 manual pages: package.1x

    CYGBUILD_MAN_SECTION_ADDITIONAL="[x]"

    #  When determining if file is Python or Perl etc, ignore compiled
    #  or library files e.g. under directory:
    #
    #    /usr/bin/lib/python<ver>/site-packages/<package>/
    #
    #  This is bash extglob pattern.

    CYGBUILD_IGNORE_FILE_TYPE="\
*@(python*/site-packages*\
|*.pyc|*.pm|.ex|.tmpl|.tmp|.dll)"

    CYGBUILD_IGNORE_ETC_FILES="\
*@(preremove|postinstall|bash_completion.d)*"

    #######################################################################
    #
    #       Private: various option arguments to programs
    #
    #######################################################################

    #   Global options for making packages (source, binary, devel)
    #   .svn = See http://subversion.tigris.org/
    #   .bzr = bazaar-ng http://bazaar-ng.org/
    #   .hg  = Mercurical http://www.serpentine.com/mercurial
    #   .mtn = and MT; See http://www.venge.net/monotone/
    #
    #   The lowercase variables are used only in this section.
    #   The uppercase variables are globals used in functions.

    cygbuild_opt_exclude_version_control="\
     --exclude=*,v \
     --exclude=.bzr \
     --exclude=.bzrignore \
     --exclude=.cvsignore \
     --exclude=.darcs \
     --exclude=.git \
     --exclude=.hg \
     --exclude=.hgignore \
     --exclude=.mtn \
     --exclude=.pc \
     --exclude=.quilt \
     --exclude=.svn \
     --exclude=.svnignore \
     --exclude=CVS \
     --exclude=MT \
     --exclude=RCS \
     --exclude=SCCS \
    "

    #   RCS and CVS version control tags cause conflicts in patches.
    #   See ident(1)

    opt_ignore_version_control="\
     --ignore-matching-lines=[$]Author.*[$] \
     --ignore-matching-lines=[$]Date.*[$] \
     --ignore-matching-lines=[$]Header.*[$] \
     --ignore-matching-lines=[$]Id.*[$] \
     --ignore-matching-lines=[$]Locker.*[$] \
     --ignore-matching-lines=[$]Log.*[$] \
     --ignore-matching-lines=[$]Name.*[$] \
     --ignore-matching-lines=[$]RCSfile.*[$] \
     --ignore-matching-lines=[$]Revision.*[$] \
     --ignore-matching-lines=[$]Source.*[$] \
     --ignore-matching-lines=[$]State.*[$] \
    "

    #   joe(1) editor leaves DEADJOE files on non-clean exit.
    #   Ruby uses .config

    cygbuild_opt_exclude_tmp_files="\
     --exclude=*.BAK \
     --exclude=*.bak \
     --exclude=*.cvsignore \
     --exclude=*.dvi \
     --exclude=*.ex \
     --exclude=*.log \
     --exclude=*.orig \
     --exclude=*.eps \
     --exclude=*.mo \
     --exclude=*.rej \
     --exclude=*.stackdump \
     --exclude=*.swp \
     --exclude=*.tmp \
     --exclude=*.TST \
     --exclude=*.tst \
     --exclude=*[~#] \
     --exclude=.[~#]* \
     --exclude=.emacs_[0-9]* \
     --exclude=.nfs* \
     --exclude=.config \
     --exclude=[~#]* \
     --exclude=a.out \
     --exclude=core \
     --exclude=.*DS_Store \
     --exclude=DEADJOE \
     --exclude=VERSION \
    "

    #  GNU automake and yacc files
    cygbuild_opt_exclude_auto_files="\
     --exclude=*.in \
     --exclude=*.am \
     --exclude=ylwrap \
     --exclude=depcomp \
     --exclude=ltmain.sh \
     --exclude=install-sh \
     --exclude=mkinstalldirs \
     --exclude=missing \
     --exclude=mdate-sh \
    "

    cygbuild_opt_exclude_info_files="\
     --exclude=*.info \
     --exclude=*.info-[0-9] \
     --exclude=*.info-[0-9][0-9] \
    "

    cygbuild_opt_exclude_man_files="\
     --exclude=*.man \
     --exclude=*.[0-9] \
     --exclude=man \
    "

    cygbuild_opt_exclude_bin_files="\
     --exclude=*.exe \
     --exclude=*.bin \
     --exclude=*.gif \
     --exclude=*.ico \
     --exclude=*.ICO \
     --exclude=*.jpg \
     --exclude=*.png \
     --exclude=*.pdf \
     --exclude=*.pyc \
     --exclude=*.xpm \
    "

    # *.elc = Emacs lisp compiled files
    cygbuild_opt_exclude_object_files="\
     --exclude=*.o \
     --exclude=*.lo \
     --exclude=*.elc \
    "

    cygbuild_opt_exclude_library_files="\
     --exclude=*.a \
     --exclude=*.la \
     --exclude=*.sa \
     --exclude=*.so \
     --exclude=*.dll \
     --exclude=*.dll.a \
    "

    cygbuild_opt_exclude_archive_files="\
     --exclude=*.[zZ] \
     --exclude=*.arj \
     --exclude=*.bz2 \
     --exclude=*.lzma \
     --exclude=*.lzop \
     --exclude=*.rzip \
     --exclude=*.gz \
     --exclude=*.rar \
     --exclude=*.tar \
     --exclude=*.tbz \
     --exclude=*.tbz2 \
     --exclude=*.tgz \
     --exclude=*.xz \
     --exclude=*.zip \
     --exclude=*.zoo \
    "

    cygbuild_opt_exclude_dir="\
     --exclude=.build \
     --exclude=.inst \
     --exclude=.sinst \
     --exclude=tmp \
    "

    local group="root"  # This always exists

    if [ -f /etc/group ]; then

        local line      # Format is => users:S-1-5-32-545:545:

        while read line
        do
            case "$line" in
                nobody*) group=nobody ; break ;;
            esac
        done < /etc/group
    fi

    CYGBUILD_TAR_GROUP="$group"

    #  1) When making snapshot copy of the original sources to elsewhere.
    #  2) when building Cygwin Net Release source and binary packages
    #
    #  perllocal.pod  is taken card by the postinstall (appending to the file)

    CYGBUILD_TAR_EXCLUDE="\
     --exclude=perllocal.pod \
     $cygbuild_opt_exclude_dir \
     $cygbuild_opt_exclude_object_files \
     $cygbuild_opt_exclude_tmp_files \
     $cygbuild_opt_exclude_version_control \
    "

    #   What files to ignore while running CygbuildInstallPackageDocs
    #   Manual files are already handled by "make install". If not,
    #   then you better write custom install script or hack the original
    #   Makefile
    #
    #   *.yo => yodl files (aterm)

    CYGBUILD_TAR_INSTALL_EXCLUDE="\
     --exclude=*.xml \
     --exclude=*.xsl \
     --exclude=*.sgml \
     --exclude=*.yo \
     --exclude=*.pretbl \
     --exclude=Makefile* \
     --exclude=stamp-vti \
     --exclude=*-sh \
     --exclude=*RISC* \
     --exclude=*bsd* \
     --exclude=*.hp* \
     $cygbuild_opt_exclude_man_files \
     $cygbuild_opt_exclude_info_files \
     $cygbuild_opt_exclude_auto_files \
     $cygbuild_opt_exclude_library_files \
     $cygbuild_opt_exclude_object_files \
     $cygbuild_opt_exclude_tmp_files \
     $cygbuild_opt_exclude_version_control \
    "

    # Ignore also libtool files generated by:
    # libtoolize --force --copy --install
    cygbuild_opt_exclude_cache_files="\
     --exclude=config.guess \
     --exclude=config.sub \
     --exclude=config.cache \
     --exclude=config.status \
     --exclude=config.log \
     --exclude=ltmain.sh \
     --exclude=install-sh \
     --exclude=depcomp \
     --exclude=missing \
     --exclude=compile \
     --exclude=libtool.m4 \
     --exclude=ltoptions.m4 \
     --exclude=ltsugar.m4 \
     --exclude=ltversion.m4 \
     --exclude=*.cache \
     --exclude=autom4te.cache \
    "

    CYGBUILD_DIFF_OPTIONS="\
     --unified \
     --recursive \
     --new-file \
     $opt_ignore_version_control \
     --exclude=.deps \
     --exclude=*.gmo \
     --exclude=*.Plo \
     --exclude=*.Tpo \
     --exclude=*.Po \
     --exclude=.pc \
     --exclude=.gitignore \
     --exclude=.hgignore \
     --exclude=.bzrignore \
     --exclude=.sgignores \
     $cygbuild_opt_exclude_cache_files \
     $cygbuild_opt_exclude_archive_files \
     $cygbuild_opt_exclude_library_files \
     $cygbuild_opt_exclude_object_files \
     $cygbuild_opt_exclude_bin_files \
     $cygbuild_opt_exclude_dir \
     $cygbuild_opt_exclude_tmp_files \
     $cygbuild_opt_exclude_version_control \
    "

    #  --forward  Ignore patches that seem to be reversed
    #  --strip=N  Strip the smallest prefix containing num leading slashes
    #             setting 0 gives the entire file name unmodified
    #  --fuzz=N   Set the maximum fuzz factor.(default is 2)

    CYGBUILD_PATCH_OPT="\
     --strip=0 \
     --forward \
     --fuzz=3 \
    "

    #  Files that can be regenerated (which can be deleted)
    CYGBUILD_FIND_OBJS="\
     -name *.o \
     -name *.a \
     -name *.la \
     -name *.exe \
     -name *.dll \
    "

    CYGBUILD_FIND_EXCLUDE="\
     -name *[#~]* \
     -name *.bak \
     -name *.orig \
     -name *.rej \
    "

    #   A bash [[ ]] match pattern to check which files are executables
    #   and would need chmod 755

    CYGBUILD_MATCH_FILE_EXE="*.@(pl|py|sh|bash|ksh|zsh)"
}

function CygbuildBootFunctionExport()
{
    local id="$0.$FUNCNAME"

    #   Externally called custom scripts may want to call back to us
    #   and refer to these functions

    export -f CygbuildCmdPrepPatch
    export -f CygbuildMakeRunInstallFixPerlMain
    export -f CygbuildVersionInfo
    export -f CygbuildDetermineReadmeFile
    export -f CygbuildLibInstallEnvironment
    export -f CygbuildCmdPublishToDir
    export -f CygbuildPatchFindGeneratedFiles
    export -f CygbuildPod2man
}

#######################################################################
#
#       EXPORTED: This function is available to external scripts
#
#######################################################################

function CygbuildLibInstallEnvironment()
{
    local id="$0.$FUNCNAME"

    #   This function can be used in install.sh, so that it can set up
    #   all the environment variables at startup
    #
    #   Include it as a first call:
    #
    #       CygbuildLibEnvironmentInstall "$@" && InstallUsingMake && ..

    instdir=${1:-""}      # ROOT DIR passed to script
    instdir=${instdir%/}  # Delete trailing slash

    export instdir
    export exec_instdir=$instdir

    export bindir="$instdir/usr/bin"
    export includedir="$instdir/usr/include"
    export libdir="$instdir/usr/lib"
    export infodir="$instdir/usr/share/info"
    export datadir="$instdir/usr/share"
    export mandir="$instdir/usr/share/man"
    export localstatedir="/var"
    export includedir="$instdir/include"

    export docdir="$instdir/$CYGBUILD_DOCDIR_FULL"

    export infobin="/usr/bin/install-info"

    export INSTALL=${CYGWIN_BUILD_INSTALL:-"/usr/bin/install"}
    export INSTALL_DATA=${CYGWIN_BUILD_F_MODES:-"--mode 644"}
    export INSTALL_BIN=${CYGWIN_BUILD_X_MODES:-"--mode 755"}
}

#######################################################################
#
#       Utility functions
#
#######################################################################

# http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD
# http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD
function CygbuildConfigGuessDownload()
{
    local url="http://anonscm.debian.org/cgit/users/hmh/autotools-dev.git/plain"
    ${test:+echo} wget -q $url/config.sub $url/config.guess
}

function CygbuildArch()
{
    uname --all | awk '{print $(NF -1) }'
}

function CygbuildArchId()
{
    local type=x86_64
    local arch=$(CygbuildArch)

    case $arch in
	i[0-9]86) type=x86 ;;
    esac

    echo $type
}

function CygbuildIsDirMatch()
{
    local dir="$1"  # ARG 1   = directory
    shift 1         # ARG 2.. = list of globs

    [ "$dir"    ] || return 1
    [ -d "$dir" ] || return 1

    local element

    CygbuildPushd

        cd "$dir" 2> /dev/null &&
        for element in $*
        do
            if [ -e "$element" ]; then
                CygbuildPopd
                return 0
            fi
        done

    CygbuildPopd

    return 1
}

function CygbuildIsDirEmpty()
{
    local dir="$1"

    [ "$dir"    ] || return 1
    [ -d "$dir" ] || return 1

    local file

    for file in $dir/.* $dir/*
    do
        [ -e "$file" ]              || continue
        [[ "$file" == */@(.|..) ]]  && continue
        return 1
    done

    return 0
}

function CygbuildFileConvertCRLF ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    [ "$file" ]      || return 0
    [ ! -s "$file" ] || return 0

    if [ ! -f "$file" ]; then
        CygbuildWarn "$id: Not a file '$file'
        return 1
    fi

    tr -d '\015' < "$file" > "$retval" &&
    mv "$retval" "$file"
}

function CygbuildFileConvertLF ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    [ "$file" ]      || return 0
    [ ! -s "$file" ] || return 0

    if [ ! -f "$file" ]; then
        CygbuildWarn "$id: Not a file '$file'
        return 1
    fi

#    awk '{ printf "%s\r\n", $0}' "$file" > "$retval" &&
    sed 's/$/\r/' "$file" &&
    mv "$retval" "$file"

}

function CygbuildFileIsCRLF ()
{
    local ctrlM=$'\015'

    [ "$1"    ] &&
    [ -f "$1" ] &&
    $EGREP --quiet --files-with-matches "[$ctrlM]" "$1" 2> /dev/null
}

function CygbuildFileCmpDiffer ()
{
    cmp "$1" "$2" > /dev/null 2>&1
    [ "$?" = "1" ]          # 0 = same, 1 = differ, 2 = error
}

function CygbuildFileCmpReplaceIfDiffer ()
{
    local from="$1"
    local to="$2"
    local msg="$3"

    if [ -s "$from" ] &&
       [ -s "$to"   ] &&
       CygbuildFileCmpDiffer "$from" "$to"
    then
        CygbuildVerb "$msg"
        mv "$from" "$to"
    fi
}

CygbuildFileSizeRead ()
{
    local file=$1

    if [ ! "$file" ] || [ ! -f "$file" ]; then
        return 1
    fi

    if [ "$STAT" ]; then
        $STAT --format=%s "$file"
        return $?
    fi

    # Traditional method. Parse ls(1) listing.

    local info=$(ls -l "$file")

    # remove FILENAME, because that distracts POSITION
    # .. 650752 2002-02-04 08:09 /home/foo/picture 14.png
    # => 650752 2002-02-04 08:09

    info=${info%$file}

    set -- $(ls -l $file)
    local count=$#

    # ... 650752 Sep 25 08:09
    local col=$(( count - 3 ))      # From the right

    # ... 650752 2002-02-04 08:09 /home/foo/file.txt
    # But sometimes the listing is different

    # FIXME: Won't work with file that contain spaces
    # .. 650752 2002-02-04 08:09

    local datecol=$(( count - 1 ))
    local date=${@:datecol:1}

    if [[ "$date" == *-* ]]; then
        col=$(( count - 2 ))
    fi

    local size=${@:col:1}

    if [[ ! "$size" == [0-9]* ]]; then
        CygbuildWarn "-- [WARN] Internal error, can't parse: $*"
        return 100
    fi

    echo $size
}

function CygbuildFileSize ()
{
    local file="$1"

    if [ ! "$file" ] || [ ! -f "$file" ]; then
        return 1
    fi

    #  This could be a symbolic link, check it
    #  lrwxrwxrwx 1 root root  27 2004-05-04 10:45  vmlinuz -> boot/vmlinuz-...

    local ls=$(ls -la "$file")

    if [[ ! "$ls" == *-\>* ]]; then
        CygbuildFileSizeRead "$file"
        return $?
    fi

    #  It is a symbolic link. Find out real path.
    #  FIXME: this does not handle multiple indirections, only one
    #  FIXME: Look CygbuildPathResolveSymlink

    local dir

    if [[ "$file" == */* ]]; then
         dir=${file%/*}
    fi

    set -- $ls

    local file=${@:(-1):1}
    local symdir

    if [[ "$file" == */* ]]; then
         symdir=${file%/*}
    fi

    local file=${file%%*/}

    (
        [ "$dir" ]    && { cd "$dir"    || return 1; }
        [ "$symdir" ] && { cd "$symdir" || return 1; }

        CygbuildFileSizeRead "$file"
    )
}

function CygbuildPythonCheckImport()
{
    local id="$0.$FUNCNAME"

    #   Returns list of import targets that are not known
    #   Do not look under site-packages

    python -c '

import sys
sys.path.remove("/usr/lib/python2.5/site-packages")

verbose = sys.argv[1]

def Check(list):
    for name in list:
        if verbose:
            print >>sys.stderr, ("Check %s" % name)
        try:
            __import__(name)
        except ImportError:
            print name

Check(sys.argv[2:])

    ' "${OPTION_DEBUG:+1}" "$@"
}

function CygbuildWasLibraryInstallMakefile ()
{
    local file

    for file in Makefile makefile */{Makefile,makefile}
    do
        [ -f "$file" ] || continue

        if $EGREP --quiet "^[^#]+(cp|chmod|install).*\<lib[a-z0-9]+\." $file
        then
            return 0
        fi
    done

    return 1
}

function CygbuildWasLibraryInstall ()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    CygbuildWasLibraryInstallMakefile && return 0

    if [ -d "$instdir_relative" ]; then
        find "$instdir_relative" \
            -type f             \
            -name "*.a"         \
            -o -name "*.la"     \
            -o -name "*.dll*"   \
            > $retval 2> /dev/null

        [ -s "$retval" ]
    else
        return 1
    fi
}

function CygbuildFileDeleteLine ()
{
    local regexp="$1"
    local file="$2"
    local tmp="$file.$$.tmp"

    if [ "$regexp" ] && [ -e "$file" ]; then
        $EGREP --invert-match --regexp="$regexp" $file > $tmp &&
        mv $tmp $file
    fi
}

function CygbuildFileDaysOld ()
{
    local file="$1"

    if [ -f "$file" ]; then
        echo -n $file | perl -ane "print -M"
    else
        return 1
    fi
}

function CygbuildGrepCheck()
{
    local regexp="$1"
    shift

    $EGREP --quiet                  \
           --ignore-case            \
           --files-with-matches     \
           --regexp="$regexp"       \
           "$@"                     \
           > /dev/null 2>&1
}

function CygbuildFindLowlevel()
{
    local arg="$1"
    shift

    find -L $arg                        \
        -type d                         \
            '('                         \
            -name ".bzr"                \
            -o -name ".git"             \
            -o -name ".hg"              \
            -o -name ".darcs"           \
            -o -name ".svn"             \
            -o -name ".mtn"             \
            -o -name "CVS"              \
            -o -name "RCS"              \
            -o -name "_MTN"             \
            ')'                         \
        -prune                          \
        -a ! -name ".bzr"               \
        -a ! -name ".git"               \
        -a ! -name ".hg"                \
        -a ! -name ".darcs"             \
        -a ! -name ".svn"               \
        -a ! -name ".mtn"               \
        -a ! -name "CVS"                \
        -a ! -name "RCS"                \
        -a ! -name "_MTN"               \
        -a ! -name "*.tmp"              \
        -a ! -name "*.ex"               \
        -a ! -name "*[#]*"              \
        -a ! -name "*~"                 \
        -a ! -name "*.orig"             \
        -a ! -name "*.rej"              \
        -a ! -name "*.bak"              \
        "$@"
}

function CygbuildFindDo()
{
    local arg="$1"
    shift

    CygbuildFindLowlevel "$arg"         \
        -o -type d                      \
            '('                         \
            -name "$instdir_relative"   \
            -o -name "$sinstdir_relative" \
            -o -name ".build"           \
            -o -name "debian"           \
            -o -name "CYGWIN-PATCHES"   \
            ')'                         \
        -prune                          \
        -a ! -name "$instdir_relative"  \
        -a ! -name "$sinstdir_relative" \
        -a ! -name ".build"             \
        -a ! -name "debian"             \
        -a ! -name "CYGWIN-PATCHES"     \
        "$@"
}

function CygbuildFindConfigFileDir()
{
    CygbuildFindDo "$builddir" -o -name "config.guess" | sed 's,/[^/]*$,,'
}

function CygbuildChmodDo()
{
    local mode="$1"
    shift

    local file

    for file in "$@"
    do
        [ -f "$file" ] || continue
        chmod ugo+x "$file" || return $?
    done
}

function CygbuildChmodExec()
{
    CygbuildChmodDo u=rwx,go+x "$@"
}

CygbuildObjDumpLibraryDepList ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    if [ ! "$file" ]; then
        CygbuildWarn "$0: [ERROR] Missing argument FILE"
        return 1
    fi

    #   objdump lists only those that the binary is linked against.
    #   Traditionally setup.hint lists *all* dependencies.

    objdump -p "$file" |
        awk '
            /KERNEL32|cygwin1|(MPR|32|ntdll).(DLL|dll)/ {
                next;
            }
            /DLL Name:/ {
                hash[$(NF)];
            }
            END{
                for (name in hash)
                {
                    print name;
                }
            }' |
         sort          # No need for --unique; awk uses hash
}

CygbuildDllToLibName ()
{
    # cygncurses-8.dll => libncurses8

    local lib ver

    for lib in "$@"
    do
        lib=${lib%.dll}
        ver=

        if [[ "$lib" == *-* ]]; then
            ver=${lib##*-}
        fi

        lib=${lib%-*}
        lib=lib${lib#cyg}

        lib=$lib$ver

        # Special cases:

        case "$lib" in
            libargp*)
                lib=libargp
                ;;
            libgcc*)
                continue                # Part of "base", so no need to mention
                ;;
            libz*)
                lib=zlib0
                ;;
            libpanelw*)
                lib=libncursesw${lib/*[a-z]/}
                ;;
            libbz2*1)
                lib=libbz2_1
                ;;
            libsqlite30)
                lib=libsqlite3_0
                ;;
            libmhash-*)
                lib=${lib/-//}
                ;;
            lib*python[0-9]*)
                lib=python
                ;;
            libcrypto* | libssl*)
                lib=libopenssl100
                ;;
            libxml2[0-9])
                # libxml2_2 => libxml2
                lib=libxml2
                ;;
            libpng[0-9][0-9][0-9][0-9])
                # libpng1515 => libpng15
                lib=${lib%[0-9][0-9]}
                ;;
            libgdk-x11-2.00)
                lib=libgtk2.0_0
                ;;
            libgdk_pixbuf-2.00)
                lib=libgdk_pixbuf2.0_0
                ;;
            libglib-2.00 | libgobject-2.00)
                lib=libglib2.0_0
                ;;
            libgsf-1114)
                lib=libgsf1_114
                ;;
            libpango-1.00)
                lib=libpango1.0_0
                ;;
            libImlib21)
                lib=libImlib2_1
                ;;
            libmagic1)
                lib=file
                ;;
            libX11[0-9])
                local nbr=""
                nbr=${lib#libX11}
                lib=libX11_$nbr
                ;;
            liblcms22)
                lib=liblcms2_2
                ;;
        esac

        echo $lib
    done
}

CygbuildCygcheckLibraryDepListFull ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    if [ ! "$file" ]; then
        CygbuildWarn "$0: [ERROR] Missing argument FILE"
        return 1
    fi

    local bin="cygcheck"
    CygbuildWhich "$bin" > $retval

    if [ ! -s $retval ] ; then
        CygbuildWarn "$0: $bin not found. Skipped"
        return 1
    fi

    bin=$(< $retval)

    #  /usr/bin/spamprobe.exe - os=4.0 img=1.0 sys=4.0
    #    D:\cygwin\bin\cygpng12.dll - os=4.0 img=1.0 sys=4.0
    #      "cygpng12.dll" v0.0 ts=2006/11/6 1:32
    #      D:\cygwin\bin\cygwin1.dll (already done)
    #                    ===========================
    #                    $(NF)

    $bin -v "$file" |
    awk -F\\ '
        / +[A-Z]:/ && ! /WINNT/ && ! /already done/ {
            str = $(NF);
            sub(" .*", "", str);
            print str;
        }' |
    sort --unique
}

CygbuildCygcheckLibraryDepList ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    # $data file includes output of cygcheck:
    #
    # D:\cygwin\bin\cygwin1.dll
    #   C:\WINNT\system32\ADVAPI32.DLL
    #     C:\WINNT\system32\NTDLL.DLL
    #     C:\WINNT\system32\KERNEL32.DLL
    #     C:\WINNT\system32\RPCRT4.DLL
    # D:\cygwin\bin\cygfontconfig-1.dll
    #   D:\cygwin\bin\cygexpat-0.dll
    #   D:\cygwin\bin\cygfreetype-6.dll
    #     D:\cygwin\bin\cygz.dll

    awk -F\\ \
    '
        ! /cygwin.*dll/ {
            next;
        }

        /cygwin1.dll/ {
            if ( match($0, "^ +") > 0 )
            {
                #  How much initial indentation there is
                minus = RLENGTH;
            }
            next;
        }

        /dll/ {
            file  = $(NF);
            space = "";

            if ( match($0, "^ +") > 0 )
            {
                space = substr($0, RSTART, RLENGTH - minus);
            }

            print space file;
        }
    ' "$file"
}

function CygbuildCygcheckLibraryDepAdjust()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"  # modifes file directly

    local setup="$DIR_CYGPATCH/setup.hint"
    local list lib

    while read lib
    do

      #  libintl already requires iconv

      if [[ "$lib" == *iconv* ]] && $EGREP --quiet 'intl' $file
      then
          CygbuildFileDeleteLine "$lib" "$file" || return 1

          if $EGREP --quiet "^ *requires:.*\b$lib" $setup ; then
              CygbuildWarn "-- [NOTE] setup.hint maybe" \
                           "unnecessary depends $lib"
          fi
      fi
    done < $file
}

function CygbuildDetermineReadmeFile()
{
    local id="$0.$FUNCNAME"
    local ret file

    for file in  $DIR_CYGPATCH/$PKG.README  \
                 $DIR_CYGPATCH/README
    do
        #   install first found file
        if [ -f "$file" ]; then
            ret="$file"
            break
        fi
    done

    if [ "$ret" ]; then
        echo $ret
    else
        return 1
    fi
}

function CygbuildDetermineDocDir()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="${1%/}"      # delete trailing slash

    CygbuildExitIfNoDir \
        "$dir" "$id: [FATAL] Call parameter DIR does not exist [$dir]"

    local ret=""
    local try=""

    #   Examples: http:://wwww.fprot.org/ uses doc_ws
    #   There must be trailing slash, because DIR may be a symlink and
    #   the content is important.

    if ls -F $dir/ |
       $EGREP --ignore-case "^doc.*/|docs?/$" > $retval
    then
        while read try
        do
            try="$dir/$try"           # Absolute path

            if [ -d "$try" ]; then
                ret=${try%/}        # Delete trailing slash
                break
            fi
        done < $retval
    fi

    echo $ret
}

function CygbuildCygcheckLibraryDepReadme()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    CygbuildDetermineReadmeFile > $retval
    local readme=$(< $retval)

    if [ ! "$readme" ]; then
        CygbuildWarn "$id: [ERROR] Can't set REAME filename"
        return 1
    fi

    local lib

    while read lib
    do
        local re=$lib
        re=${re//\+/\\+}                # libstcc++ =>  libstcc\+\+

        if ! $EGREP --quiet " \<$re" $readme   # <LIB>-devel
        then
            CygbuildWarn "-- [ERROR] $PKG.README does not mention $lib"
        fi
    done < $file
}

CygbuildCygcheckLibraryDepSetup ()
{
    local id="$0.$FUNCNAME"
    local file="$1"
    local lib

    #  Check that all are listed

    while read lib
    do
        local re=$lib
        re=${re//\+/\\+}                # libstcc++ =>  libstcc\+\+

        if ! $EGREP --quiet "^ *requires:.*\<$re\>" $setup
        then
            CygbuildWarn "-- [ERROR] setup.hint lacks $lib"
        fi
    done < $file
}

function CygbuildCygcheckLibraryDepGrepPgkNamesCache()
{
    #   NOTE: informational messages are written to stderr
    #   because this function returns list of depends.

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"  # list of library names
    local cache="$2"

    if [ ! "$file" ] || [ ! -e "$file" ]; then
        CygbuildDie "[FATAL] $id: empty 'file' argument"
    fi

    # Cache lines in format: <package path>:<tar listing>.
    # Here is example of the "path":
    # .../release/X11/xorg-x11-bin-dlls/xorg-x11-bin-dlls-6.8.99.901-1.tar.bz2

    #   Always depends on this

    echo "cygwin" > $retval.collect

    tr '\n' ',' < $file > $retval

    [ -s $retval ] || return 1

    local list=$(< $retval)

    local lib list
    awk -F: \
    '
        function setup(val, name, space, i, len) {
            len = split(liblist, arr, ",");

            #  Convert "A,  B,C, D" into
            #  re = "(A|B|C)$"

            for (i=1; i < len ; i++)
            {
                val   = arr[i];
                name  = val;
                space = "";

                if ( match (val, "^ +") > 0 )
                {
                    space = substr(val, 1, RLENGTH);
                }

                if ( match (val, "[^ ]+") > 0 )
                {
                    name = substr(val, RSTART, RLENGTH);
                }

                HASH[name] = space;

                if ( add )
                {
                    RE = RE "|" name;
                }
                else
                {
                    RE  = name;
                    add = 1;
                }
#print i " VAL [" val "] space [" space "] RE [" RE "]";
            }

            if ( length(RE) > 0 )
            {
                RE = "(" RE ")$";
            }
        }

        {
            if ( ! boot )
            {
                setup();
                boot = 1;
            }

            if ( match($0, RE) > 0 )
            {
                lib   = substr($0, RSTART, RLENGTH);
                space = HASH[lib];

                path=$1;
                gsub(".*/", "", path);
                gsub("-[0-9].*", "", path);

                DEPENDS[lib]   = path;
                DEP_SPACE[lib] = space;  # Save indentation information
            }
        }

        END {
            for (name in HASH)
            {
                dep = DEPENDS[name];

                if ( dep == "" )
                {
                    dep ="[WARN] determine depends";
                }

                printf("%-25s %s\n", name, dep);
            }
        }

    ' liblist="$list" $cache > $retval.tmp

    if [ -s $retval.tmp ]; then
        sed 's/^/   /' $retval.tmp >&2
        awk '! /cannot/ {print $2}' $retval.tmp >> $retval.collect
    fi

    [ -s $retval.collect ] && cat $retval.collect
}

CygbuildCygcheckLibraryDepGrepTraditonal()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if [ ! "$CYGCHECK" ]; then
        CygbuildVerb "-- [NOTE] cygcheck not available. Skipped"
        return 1
    fi

    local file

    for file in "$@"
    do
        if [[ ! "$file" == /* ]]; then
            CygbuildWhich "$file" > $retval
            [ -s $retval ] && file=$(< $retval)
        fi

        if [ ! -f "$file" ]; then
            CygbuildWarn "-- [WARN] No such file: $file"
            continue
        fi

        # xorg-x11-bin-dlls-6.8.99.901-1 => xorg-x11-bin-dlls
        $CYGCHECK -f $file | sed -e 's,-[0-9].*,,'

    done | sort --unique
}

CygbuildCygcheckLibraryDepGrepPgkNamesMain()
{
    local file="$1"
    local cache="/var/cache/cygbug/package/list/file.lst"

    if [ ! "$file" ]; then
        CygbuildDie "$0: Missing arg1 FILE"
    fi

#    if [ -f $cache ]; then
#        CygbuildCygcheckLibraryDepGrepPgkNamesCache "$file" "$cache"
#    else
        CygbuildCygcheckLibraryDepGrepTraditonal cygwin1.dll $(< $file)
#    fi
}

function CygbuildCygcheckLibraryDepMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"
    local datafile="$2"

    if [ ! "$file" ] || [ ! -f "$file" ]; then
        CygbuildDie "$0: Missing arg1 FILE"
    fi

    local setup="$DIR_CYGPATCH/setup.hint"

    CygbuildEcho "-- Trying to resolve depends for" ${file#$srcdir/}

    # Old method, do not use
    # CygbuildCygcheckLibraryDepList "$datafile" > "$retval"

    CygbuildCygcheckLibraryDepListFull "$file" > "$retval"

    if [ ! -s $retval ]; then
        CygbuildEcho "-- No dependencies found"
        return 0
    fi

    if CygbuildCygcheckLibraryDepGrepPgkNamesMain \
       "$retval" > "$retval.pkglist"
    then
        CygbuildCygcheckLibraryDepAdjust "$retval.pkglist"

        sed 's/^ \+//' "$retval.pkglist" |
            sort --unique |
            sed 's/^/   depends: /'

        CygbuildObjDumpLibraryDepList "$file" > "$retval.obj"

        [ -s "$retval.obj" ] || return 0

        CygbuildDllToLibName $(< $retval.obj) > "$retval.libnames"

        CygbuildEcho "-- Objdump direct dependencies"
        cat "$retval.obj"

        CygbuildCygcheckLibraryDepSetup  "$retval.libnames"
        CygbuildCygcheckLibraryDepReadme "$retval.libnames"
    fi
}

function CygbuildCygcheckMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dummy="$*"                    # For debug
    local file

    [ "$CYGCHECK" ] || return 0

    for file in "$@"
    do
        file=${file#$srcdir/}           # Make relative path

        CygbuildEcho "-- Wait, listing depends"
        $CYGCHECK "$file" # | tee $retval 2> /dev/null

        CygbuildCygcheckLibraryDepMain "$file" "$retval"
    done
}

function CygbuildCheckRunDir()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #  Do just a quick sweep, nothing extensive

    CygbuildIsGbsCompat ||

    if [[ "$(pwd)" == *@(.sinst|.build|.inst|CYGWIN-PATCHES)* ]]
    then
        CygbuildWarn "-- [WARN] Current directory is not source ROOT $srcdir"
        return 1
    fi
}

function CygbuildVersionInfo()
{
    local id="$0.$FUNCNAME"
    local str="$1"

    #   Debian uses scheme: package_VERSION-REL.orig.tar.gz
    #
    #   1. Delete path and see if the last name matches:
    #
    #       /this/dir/package-NN.NN
    #       /this/dir/package-YYYYMMDD
    #
    #   2. If that does not work, then perhaps the package is being
    #   verified:
    #
    #       /usr/src/build/neon/foo-NN.NN/.build/tmp/verify
    #

    echo -n "$str" | perl -e \
    '
        $_  = <>;
        s,.+/,,;
        s,\.(tar\.(gz|bz2|lzma|xz|lzop)|zip|t[gb]z)$,,;
        s,\.orig$,,;
        s,-src$,,;

        # Remove release number (if any)
        # e.g. xterm-299, where 229 is NOT a release to be removed

        if ( /^(.+)-v?(\d|1\d?)$/i )
        {
            $_   = $1;
            $rel = $2;
        }

        @a = /^(.+)[-_]v?([\d.]+[_-]?rc.*)/i;

        #  foo_0.4.0-test5
        #  foo-1.3.0-rc1

        @a = /^(.+)[-_]v?(\d\.\d.*)/i unless @a;

        @a = /^(.+)[-_]v?(.*\d.*)/i unless @a;

        if ( @a )
        {
            push @a, $rel if $rel;
            print qq(@a\n);
            exit 0;
        }

        # foo4.16.0.70

        @a = /^([a-z_-]*[A-Za-z])([\d.]*\d.*)/i ;

        if ( @a )
        {
            push @a, $rel if $rel;
            print qq(@a\n);
            exit 0;
        }

        exit 123;
    '
}

function CygbuildDefileInstallVariables()
{
    local id="$0.$FUNCNAME"

    local prefix=${1:-"usr"}
    local prefix_man=${2:-"share/man"}
    local prefix_info=${3:-"share/info"}
    local prefix_data=${4:-"share"}
    local prefix_sysconf=${5:-"/etc"}

    local prefix_lib=${6:-"lib"}
    local prefix_inc=${7:-"include"}
    local prefix_doc=${8:-"share/doc"}
    local prefix_state=${9:-"/var"}
    local prefix_libexec=${10:-"lib"}

    if [[ "$prefix" == /* ]]; then
        CygbuildDie "[ERROR] Can't use abosolute prefix value: $prefix" \
            "the install will always happen into subdirectory" \
            $sinstdir_relative/
    fi

    #   Do not add trailing slash. The exports are needed because variables
    #   are used in subshells

    export CYGBUILD_PREFIX=/$prefix                             # global-def
    export CYGBUILD_DOCDIR_PREFIX_RELATIVE=$prefix/share        # global-def
    export CYGBUILD_DOCDIR_RELATIVE=$prefix_doc                 # global-def
    export CYGBUILD_DOCDIR_FULL=$prefix/$prefix_doc             # global-def
    export CYGBUILD_DOCDIRCYG_FULL=$prefix/$prefix_doc/Cygwin   # global-def
    export CYGBUILD_MANDIR_RELATIVE=$prefix_man                 # global-def
    export CYGBUILD_MANDIR_FULL=$prefix/$prefix_man             # global-def
    export CYGBUILD_INFO_FULL=$prefix/$prefix_info              # global-def

    export CYGBUILD_SYSCONFDIR=$prefix_sysconf                  # global-def

    #   Not included:
    #    target=i686-pc-cygwin
    #    host=i686-pc-linux
    #    --host $host
    #    --target $target
    #    --srcdir $srcdir
    #    --includedir $prefix/include

    CYGBUILD_CONFIGURE_OPTIONS="\
 --prefix=$CYGBUILD_PREFIX \
 --exec-prefix=$CYGBUILD_PREFIX \
 --bindir=$CYGBUILD_PREFIX/bin \
 --sysconfdir=$prefix_sysconf \
 --libexecdir=$CYGBUILD_PREFIX/$prefix_libexec \
 --localstatedir=$prefix_state \
 --datadir=$CYGBUILD_PREFIX/$prefix_data \
 --mandir=$CYGBUILD_PREFIX/$prefix_man \
 --infodir=$CYGBUILD_PREFIX/$prefix_info \
 --libdir=$CYGBUILD_PREFIX/$prefix_lib \
 --includedir=$CYGBUILD_PREFIX/$prefix_inc \
 --with-intl \
"
}

function CygbuildDefileInstallVariablesUSRLOCAL()
{
    CygbuildDefileInstallVariables  \
    "usr/local"                     \
    "man"                           \
    "info"                          \
    "share"                         \
    "/usr/local/etc"
}

function CygbuildDefineVersionVariables()
{
    local id="$0.$FUNCNAME"

    local str="$1"
    local -a arr

    if [ "$CYGBUILD_STATIC_VER_STRING" = "$str" ]; then
        arr=( ${CYGBUILD_STATIC_VER_ARRAY[*]} )
    else

        local retval="$CYGBUILD_RETVAL.$FUNCNAME"

        if ! CygbuildVersionInfo "$str" > $retval ; then
            CygbuildDie "-- [ERROR] Not inside directory package-N.N/" \
                "Can't read version info: $str"
        fi

        [ -s $retval ] ||
            CygbuildDie "$id: Can't read disk version info: $str"

        arr=( $(< $retval) )
        dummy="${arr[*]}"  #  For debugging

        CYGBUILD_STATIC_VER_ARRAY=( ${arr[*]} )
    fi

    local count=${#arr[*]}

    if [[ $count -gt 1 ]]; then
        CYGBUILD_STATIC_VER_PACKAGE=${arr[0]}
        CYGBUILD_STATIC_VER_VERSION=${arr[1]}
        CYGBUILD_STATIC_VER_RELEASE=${arr[2]}
        CYGBUILD_STATIC_VER_STRING="$str"
    fi

    #  Return status: Do we have the VERSION?

    [[ "$CYGBUILD_STATIC_VER_VERSION" == *[0-9]* ]]
}

function CygbuildStrRemoveExt()
{
    local id="$0.$FUNCNAME"

    # Remove compression extensions
    # foo-1.13-src.tar.gz => foo-1.13

    local str="$1"

    str=${str##*/}          # Remove path
    str=${str%.tar.gz}
    str=${str%.tar.bz2}
    str=${str%.tar.lzma}
    str=${str%.tar.xz}
    str=${str%.tar.lzop}
    str=${str%.tgz}
    str=${str%.tbz2}
    str=${str%.tbz}
    str=${str%-src}
    str=${str%.orig}

    echo $str
}

function CygbuildStrPackage()
{
    local id="$0.$FUNCNAME"

    # Like reading PACKAGE-1.13-1-src.tar.gz
    # foo-1.13-1-src.tar.gz => foo

    local str="$1"

    if CygbuildDefineVersionVariables $str ; then
        echo $CYGBUILD_STATIC_VER_PACKAGE
    else
        CygbuildDie "$id: [FATAL] CygbuildDefineVersionVariables($str) failed."
    fi
}

function CygbuildStrVersionRelease()
{
    local id="$0.$FUNCNAME"

    # Like reading foo-VERSION-RELEASE-src.tar.gz
    # foo-1.13-1-src.tar.gz => 1.13-1

    local str="$1"

    if CygbuildDefineVersionVariables $str ; then
        if [ "$CYGBUILD_STATIC_VER_RELEASE" ]; then
            echo $CYGBUILD_STATIC_VER_VERSION-$CYGBUILD_STATIC_VER_RELEASE
        fi
    fi
}

function CygbuildStrRelease()
{
    local id="$0.$FUNCNAME"

    # Like reading foo-1.13-RELEASE-src.tar.gz
    # foo-1.13-1-src.tar.gz => 1

    local str="$1"

    if CygbuildDefineVersionVariables $str ; then
        echo $CYGBUILD_STATIC_VER_RELEASE
    fi
}

function CygbuildStrVersion()
{
    local id="$0.$FUNCNAME"

    # Like reading foo-VERSION-1-src.tar.gz
    # foo-1.13-1-src.tar.gz => 1.13

    local str="$1"

    if CygbuildDefineVersionVariables $str ; then
        echo $CYGBUILD_STATIC_VER_VERSION
    fi
}

function CygbuildIsSrcdirOk()
{
    local exitmsg="$1"

    #  Verify that the source root is well formed package-N.N/

    if [ "$srcdir" ]; then
        if [[ $srcdir == *-*[0-9]* ]]; then
            :
        elif [[ $srcdir == *-*[0-9]*.orig ]]; then
            #   Accept Debian orignal packages
            :
        else
            [ "$exitmsg" ] && CygbuildDie "$exitmsg"
            return 1
        fi
    fi
}

function CygbuildIsBuilddirOk()
{
    # Check if builddir has been populated using shadow.

    if [ "$builddir" ] && [ -d "$builddir" ]; then

        #   Some packages contain only TOP level directories so we must
        #   peek inside $builddir/*/* to see if it there are symlinks
        #   (made by shadow)

        local item

        for item in $builddir/* $builddir/*/*
        do
            if [ -h "$item" ]; then       # First symbolic link means OK
                return 0
            fi
        done
    fi

    return 1
}

function CygbuildPathResolveSymlink()
{
    #   FIXME: Check the logic if it's correct

    #   Try to resolve symbolic link.
    #   THIS IS VERY SIMPLE, NOT RECURSIVE if additional
    #   support programs were not available

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local bin="$1"
    local path="."

    if [[ $bin == */* ]]; then
        path=${bin%/*}
        bin=${bin##*/}
    fi

    local abs="$path/$bin"
    local try

    if [[ ! -h $abs  &&  $abs == /*  ]]; then

        try="$abs"

    elif [[ ! -h $abs  &&  ($abs == ./* || $abs == ../*) ]]; then

        #   No need for external program, we can find out
        #   this by ourself

        local path=${bin%/*}
        local name=${bin##*/}

        try=$(cd "$path"; pwd)/$name

    elif [ "" ] && [ -x /usr/bin/chase ]]; then

        #  DISABLED for now.

        /usr/bin/chase "$abs" > $retval

        [ -s $retval ] && try=$(< $retval)

    elif [ -x /usr/bin/readlink ]; then

        #  readlink is unreliable, because it doesn't return path, if the
        #  path is not a symlink. It returns empty.

        /usr/bin/readlink "$abs" > $retval

        if [ -s $retval ]; then
            try=$(< $retval)

            if [ "$try" ] && [[ ! "$try" == */* ]]; then
                try="$path/$try"
            fi
        fi

    elif [ "" ] && [ -x /usr/bin/namei ]]; then

        # DISABLED. The output of name cannot be easily parsed,
        # because it doesn't output single path, but a tree notation.
        #
        # d /
        # d usr
        # d src
        # d build
        # d build
        # d xloadimage
        # l xloadimage-4.1 -> xloadimage.4.1
        #   d xloadimage.4.1
        # d .inst
        # d usr
        # d share
        # d man
        # d man1
        # l xsetbg.1 -> xloadimage.1
        #   - xloadimage.1
        #

        /usr/bin/namei $abs \
            | tail --lines=3 \
            | $EGREP --ignore-case ' l .* -> ' \
            > $retval

        if [ -s $retval ]; then
            local -a arr
            arr=( $(< $retval) )

            local count=${#arr[*]}

            if [ "$count" = "4" ]; then
                try=${arr[3]}
            fi
        fi
    fi

    if [ "$try" ]; then
        echo "$try"
    else
        return 1
    fi
}

function CygbuildPathAbsoluteSearch()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local bin="$1"

    if [ ! "$bin" ]; then
        CygbuildWarn "$id: [ERROR] parameter 'bin' is empty"
        return 1
    fi

    if [[ "$bin" != */* ]]; then

        local tmp

        CygbuildWhich $bin > $retval &&
        tmp=$(< $retval)

        #   Perhaps the file was not executable
        [ "$tmp" ] && bin=$tmp
    fi

    local try

    CygbuildPathResolveSymlink "$bin" > $retval
    [ -s $retval ] && try=$(< $retval)

    if [ "$try" ]; then
        bin="$try"
    fi

    echo $bin
}

function CygbuildPathAbsolute()
{
    local id="$0.$FUNCNAME"
    local p="$1"

    if [ "$p" ] && [ -d "$p" ]; then
        p=$(cd "$p" && pwd)

    elif [[ "$p" == /*  &&  -f "$p" ]]; then
        # Nothing to do, it is absolute already
        true

    elif [[ "$p" == */* ]]; then

        #   Perhaps there is filename too? dir/dir/file.txt
        #   Remove last portion

        local file=${p##*/}
        local dir=${p%/*}

        if [ -d "$dir" ]; then
            dir="$(cd "$dir" ; pwd)"
            p="$dir/$file"
        fi

    else
        if [ -f "$p" ]; then
            p="$(pwd)/$p"
        fi
    fi

    if [ "$p" ]; then
        echo "$p"
    else
        return 1
    fi
}

function CygbuildScriptPathAbsolute()
{
    local id="$0.$FUNCNAME"
    local bin="$1"

    if [ ! "$bin" ]; then
        CygbuildWarn "$id: [ERROR] parameter 'bin' is empty"
        return 1
    fi

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local -a cache=( ${CYGBUILD_STATIC_ABSOLUTE_SCRIPT_PATH[*]} )
    local ret

    if [[ "${cache[0]}" == $bin* ]]; then
        ret=${cache[1]}
    else
        CygbuildPathAbsoluteSearch "$bin" > $retval &&
        ret=$(< $retval)

        if [ ! "$ret" ]; then
            CYGBUILD_STATIC_ABSOLUTE_SCRIPT_PATH=($bin $ret)    # global-def
        fi
    fi

    if [ "$ret" ]; then
        echo $ret
    else
        return 1
    fi
}

function CygbuildBuildScriptPath()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   Source packages includes script-VERSION-RELEASE.sh
    #   and not just script.sh, so $0 cannot always be used directly.

    local name="$0"

    #   If there is path component, then perhaps script is called
    #   by ./script-NN.NN-1.sh, skip that case

    if [[ "$name" != */*  &&  -f "./$name" ]]; then
        echo $(pwd)/$name

    elif [[ "$name" = ./*  &&  -f "./$name" ]]; then
        name=${name#./}
        echo $(pwd)/$name

    elif [[ "$name" == */*  &&  -f "$name" ]]; then
        echo $name

    else
        name=${name##*/}

        CygbuildScriptPathAbsolute $name > $retval
        [ -s $retval ] && echo $(< $retval)

    fi
}

function CygbuildTarDirectory()
{
    #   Return tar package's top level directory if any

    local id="$0.$FUNCNAME"
    local file="$1"

    if [ ! "$file" ]; then
        CygbuildWarn "$id: FILE parameter is empty"
        return 1
    fi

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    tar --list --verbose --file=$file > $retval || return $?

    if [ ! -s $retval ]; then
        CygbuildWarn "$id: [ERROR] Can't read content of $file"
        return 1
    fi

    #   $(NF) will give last field from line:
    #   -rw-r--r-- root/root 23206 2004-02-10 02:31:56 foo-N.N/COPY
    #
    #   The gsub() calls will handle cases:
    #   a) ./package-nn.nn/
    #   b) package-nn.nn/
    #
    #   Different paths are gathered in HASH (associtive array) and
    #   there will be only one, if top level directory exists.
    #   Skip symbolic links.
    #
    #   NOTE: There may be files with spaces, so we must rely on colum 6.
    #
    #   ... foo-N.N/testdir/with space in name

    local dirfile="$retval.dir"

    awk  '                              \
        /->/ {                          \
            next                        \
        }                               \
        {                               \
            path = $6;                  \
            gsub("[.]/", "", path );    \
            gsub("/.*", "", path );     \
            hash[ path ] = 1;           \
        }                               \
        END {                           \
            for (i in hash)             \
            {                           \
                print i;                \
            }                           \
        }                               \
        '                               \
        $retval > $dirfile || return $?

    wc -l < $dirfile > $retval.count
    local lines=$(< $retval.count)

    if [ "$lines" = "1" ]; then
        echo $(< $dirfile)
    fi
}

function CygbuildMakefileName()
{
    local id="$0.$FUNCNAME"
    local dir=${1:-$(pwd)}
    shift              # Rest of the parameters are other files to try

    local file path

    for file in GNUMakefile Makefile makefile ${1+"$@"} \
        unix/makefile unix/Makefile \
        gnu/makefile gnu/Makefile
    do
        path="$dir/$file"

        if [ -f "$path" ]; then
            echo "$path"
            break
        elif [ -h "$path" ]; then
            CygbuildWarn "-- [ERROR] broken links." \
                 "Perhaps sources moved and you need to run again [shadow]."
            ls -l --all "$path"
            break
        fi
    done
}

function PackageUsesLibtoolMain()
{
    CygbuildGrepCheck \
        '^[^#]*\blibtool|--mode=(install|compile|link)'  \
        "$@"
}

function PackageUsesLibtoolCompile ()
{
    CygbuildGrepCheck '--mode=compile' "$@"
}

function MakefileUsesRedirect()
{
    #   Check if the current (top level) makefile use -C

    local id="$0.$FUNCNAME"
    local file="$1"

    if [ ! "$file" ] || [ ! -f "$file" ]; then
        return 1
    fi

    #   See if we can find:  $(MAKE) -C src

    CygbuildGrepCheck '^[^#]+make[)[:space:]]+-C' $file
}

function CygbuildIsMakefileTarget()
{
    local id="$0.$FUNCNAME"
    local target="$1"

    if [ ! "$target" ]; then
        CygbuildDie
    fi

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName > $retval

    local file
    [ -s $retval ] && file=$(< $retval)

    if [ ! "$file" ]; then
        return 1
    fi

    CygbuildGrepCheck "^$target:" $file
}

function CygbuildIsPythonLibrary()
{
    # Some libraries cntains following texts:
    #
    #     Topic :: Software Development :: Libraries :: Python Modules

    CygbuildGrepCheck \
        "Libraries[[:space:]]*::[[:space:]]*Python[[:space:]]*Modules" \
        setup.py
}

function CygbuildIsPythonSetuptools()
{
    # Check if setup.py uses "setuptools"

    CygbuildGrepCheck \
        "setuptools" \
        setup.py
}

function CygbuildIsMakefileCplusplus()
{
    #   FIXME: Any better file patterns?
    #   Consider Makefile.SunOS, Makefile.linux and this is not
    #   very reliable way to test it.

    CygbuildGrepCheck "^[^#]+=[[:space:]]*[gc][+][+]" \
        *Makefile \
        makefile *.mk \
        src/*Makefile \
        src/makefile \
        src/*.mk
}

function CygbuildIsMakefileCstandard()
{
    # FIXME: Any better file patterns?
    CygbuildGrepCheck "^[^#]+=[[:space:]]*(gcc|cc)" \
        *Makefile \
        makefile *.mk \
        src/*Makefile \
        src/makefile \
        src/*.mk
}

function CygbuildIsCplusplusPackage()
{
    #   FIXME: This won't be correct for packages which contain
    #   several different programs that are both C/C++,
    #   like:
    #
    #       root/application-a/C
    #       root/application-b/C++
    #       root/application-b/C
    #
    #   in this case the first found, would determine that *all*
    #   would be "C", which is not correct.

    #   Search under any directory

    local file

    for file in *.hh *.cc *.cpp *.cxx */*.hh */*.cc */*.cpp  */*.cxx
    do
        [ -f "$file" ] && return 0
    done

    local retval=$RETVAL.$FUNCNAME

    find .                          \
        -maxdepth 3                 \
        -iname "*makefile"          \
        > $retval

    [ -s $retval ] || return 1

    while read file
    do
        if $GREP --quiet "^[[:space:]]*CC[[:space:]]*=[^#]*g[+][+]" "$file"
        then
            return 0
        fi
    done < $retval

    return 1
}

function CygbuildMakefileRunTarget()
{
    local id="$0.$FUNCNAME"
    local target="$1"
    local dir="$2"
    local opt="$3"

    [ ! "$dir"    ] && dir=$builddir
    [ ! "$target" ] && target="all"

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName $dir > $retval

    local makefile
    [ -s $retval ] && makefile=$(< $retval)

    if [ ! "$makefile" ]; then
        if [ "$opt" != "nomsg" ]; then
            CygbuildEcho "-- No Makefile found, nothing to [$target] in $dir"
        fi
        return 0
    fi

    CygbuildPushd

        cd "$dir" || exit 1

        if CygbuildIsMakefileTarget $target ; then
            make -f $makefile $target
        elif [ "$verbose" ]; then
            CygbuildWarn "-- [NOTE] No target '$target' in" \
                         ${makefile#$srcdir/}
        fi

    CygbuildPopd
}

function CygbuildFileTypeByExtension()
{
    local file="$1"
    local ret

    case "$file" in
        *.sh) ret="shell"   ;;
        *.py) ret="python"  ;;
        *.pl) ret="perl"    ;;
        *.rb) ret="ruby"    ;;
        *) return 1         ;;
    esac

    echo $ret
}

function CygbuildFileTypeByFile()
{
    local file="$1"
    local ret
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local notes

    file $file > $retval
    [ -s $retval ] && notes=$(< $retval)

    if [[ "$notes" == *perl*  ]]; then
        ret="perl"
    elif [[ "$notes" == *python*  ]]; then
        ret="python"
    elif [[ "$notes" == *shell*  ]]; then
        ret="shell"
    elif [[ "$notes" == *executable*  ]]; then
        ret="executable"
    elif [[ "$notes" == *ASCII* ]]; then
        #  Hm, file in disguise. Can we find bang-slash?

        $EGREP '^#!' $file > $retval
        [ -s $retval ] && notes=$(< $retval)

        if [[ "$notes" == *@(bash|/sh|/ksh|/csh|/tcsh) ]]; then
            ret="shell"
        elif [[ "$notes" == *perl* ]]; then
            ret="perl"
        elif [[ "$notes" == *python* ]]; then
            ret="perl"
        fi
    fi

    if [ "$ret" ]; then
        echo $ret
    else
        return 1
    fi
}

function CygbuildFileIgnore()
{
    [[ $1 == $CYGBUILD_IGNORE_FILE_TYPE ]]
}

function CygbuildFileTypeMain()
{
    local file="$1"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #  We must not check binary files etc.

    CygbuildFileIgnore "$file" && return 10

    CygbuildFileTypeByExtension "$file" > $retval ||
    CygbuildFileTypeByFile      "$file" > $retval ||
    return 1

    echo $(< $retval)
}

function CygbuildIsCvsPackage()
{
    [ -f "$srcdir/CVS/Root" ] &&  [ -f "$srcdir/CVS/Repository" ]
}

function CygbuildIsSvnPackage()
{
    [ -f "$srcdir/.svn/entries" ] &&  [ -d "$srcdir/.svn/props" ]
}

function CygbuildIsMercurialPackage()
{
    [ -f "$srcdir/.hg/data" ] &&  [ -f "$srcdir/.hg/hgrc" ]
}

function CygbuildIsGitPackage()
{
    [ -f "$srcdir/.git/HEAD" ] &&  [ -f "$srcdir/.git/config" ]
}

function CygbuildIsBzrPackage()
{
    [ -f "$srcdir/.bzr/inventory" ] &&  [ -d "$srcdir/inventory-store" ]
}

function CygbuildIsDarcsPackage()
{
    [ -d "$srcdir/.darcs" ]
}

function CygbuildIsMonotonePackage()
{
    [ -d "$srcdir/.mtn" ]
}

function CygbuildVersionControlType()
{
    #   RCS/ and ARCH are not tested because they are very old

    if CygbuildIsCvsPackage ; then
        echo "cvs"
    elif CygbuildIsSvnPackage ; then
        echo "svn"
    elif CygbuildIsGitPackage ; then
        echo "git"
    elif CygbuildIsMercurialPackage ; then
        echo "mercurial"
    elif CygbuildIsBzrPackage ; then
        echo "bzr"
    elif CygbuildIsDarcsPackage ; then
        echo "darcs"
    elif CygbuildIsMonotonePackage ; then
        echo "mtn"
    else
        return 1
    fi
}

function CygbuildIsPerlPackage()
{
    [ -f "$srcdir/Makefile.PL" ]
}

function CygbuildIsPythonPackage()
{
    [ -f "$srcdir/setup.py" ]
}

function CygbuildIsRubyPackage()
{
    [ -f "$srcdir/setup.rb" ]
}

function CygbuildIsCmakePackage()
{
    [ -f "$srcdir/CMakeLists.txt" ]
}

function CygbuildIsAutomakePackage()
{
    [ -f "$srcdir/Makefile.in" ] || [ -f "$srcdir/makefile.in" ]
}

function CygbuildIsAutoconfPackage()
{
    [ -f "$srcdir/configure.in" ]
}

function CygbuildIsAutotoolPackage()
{
    CygbuildIsAutomakePackage && CygbuildIsAutoconfPackage
}

function CygbuildIsX11Package()
{
    local id="$0.$FUNCNAME"
    local status=1              # Failure by defualt

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName $(pwd) Makefile.in > $retval

    [ -s $retval ] || return 2

    local file=$(< $retval)

    if [ -f "$file" ]; then
        CygbuildGrepCheck "/X11/" $file
        status=$?
    fi

    return $status
}

function CygbuildIsX11appDefaults()
{
    local status=1              # Failure by defualt

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName $(pwd) Makefile.in > $retval

    [ -s $retval ] || return 2

    local file=$(< $retval)

    if [ -f "$file" ]; then
        CygbuildGrepCheck "/app-defaults" $file configure.in configure
        status=$?
    fi

    return $status
}

function CygbuildIsDestdirSupported()
{
    local id="$0.$FUNCNAME"

    CygbuildExitIfNoDir "$srcdir" \
        "$id: [FATAL] variable '$srcdir' not defined [$srcdir]."

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local module="$CYGBUILD_STATIC_PERL_MODULE"

    [ "$module" ] || return 1

    #   egrep could find  .... '^[^#]+[$][{(]DESTDIR', but to do
    #   it reliably, we need Perl.

    local debug=${OPTION_DEBUG:-0}

    perl -e "require qq($module);  SetDebug($debug); \
              MakefileDestdirSupport(qq($srcdir), qq(-exit));"
}

function CygbuildDependsList()
{
    #   Read the depends line

    local file=$DIR_CYGPATCH/setup.hint

    if [ ! -f "$file" ]; then
        return 1
    else
        sed -ne 's/requires:[ \t]*//p' $file
    fi
}

function CygbuildIsTemplateFilesInstalled()
{
    #   If proper setup has been done, this file exists

    local file=$DIR_CYGPATCH/setup.hint

    [ -f "$file" ]
}

function CygbuildSourceDownloadScript()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if ls *$SCRIPT_SOURCE_GET_BASE > $retval 2> /dev/null ; then
        local -a arr=( $(< $retval))

        local len=${#arr[*]}
        local file

        if [ "$len" = "1" ]; then
            file=${arr[0]}
        fi

        echo $file
    else
        return 1
    fi
}

function CygbuildGetOneDir()
{
    #   Return one Directory, if there is only one.

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local from=${1:-"."}

    #   AWK get all entries that include "/" and then deleted trailing "/"

    ls -F $from | awk  '/\/$/ && ! /tmp/ {        \
        sub("/$", "");                              \
        print;                                      \
        exit;                                       \
        }'                                          \
        > $retval

    local -a arr=$(< $retval)

    local count=${#arr[*]}

    if [ "$count" = "1" ]; then
        echo ${arr[0]}
    else
        return 1
    fi
}

function CygbuildMoveToTempDir()
{
    local id="$0.$FUNCNAME"

    #   Move all files execpt cygbuild*.sh from DIR to temporary directory,
    #   which is deleted beforehand.
    #
    #   Return TEMP DIR
    #
    #   This function is meant for archives that do not contain directory
    #   structure at all, but unpack in place. The idea is to move files
    #   to separate directory to get clean unpack.

    local dir="$1"
    local dest=${2:-"tempdir"}     # optional parameter, if no name given

    dir=$(cd "$dir" ; pwd)

    if [ ! "$dir" ]; then
        CygbuildWarn "$id: [ERROR] DIR input parameter is empty"
        return 1
    fi

    local temp=$dir/$dest

    if [ -d "$temp" ]; then
        rm -rf "$temp"
    fi

    mkdir $temp || return 1

    #   Move everything else, but the directory itself and
    #   the build script, that does not belong to the original
    #   package

    CygbuildPushd
        cd "$dir" &&
        mv $(ls | $EGREP --invert-match "$dest|cygbuild.*sh" ) $dest
    CygbuildPopd

    echo $temp
}

function CygbuildFilesExecutable()
{
    local id="$0.$FUNCNAME"
    local dir=${1:-"."}
    local opt=${2:-""}

    local pwd=$(pwd)
    dir=${dir#$pwd/}        #   Shorten the path a bit

    #   Find all files that look like executables from DIR
    #   The extra options for FIND are sent in OPT.

#    set -o noglob

        find -L $dir            \
        -type f                 \
        '('                     \
            -name "*.exe"       \
            -o -name "*.sh"     \
            -o -name "*.pl"     \
            -o -name "*.py"     \
            -o -perm /u+x,g+x,o+x \
        ')'                     \
        -o  -path "*/bin/*"     \
        -o  -path "*/sbin/*"    \
        $opt

#    set +o noglob
}

function CygbuildFileConvertToUnix()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if [ $# -eq 0 ]; then
        CygbuildWarn "$id: [ERROR] Argument list \$* is empty"
        return 1
    fi

    ls "$@" > $retval 2> /dev/null

    [ -s $retval ] || return 2

    perl -e '
        for my $file (@ARGV)
        {
            ! -f $file  and next;

            /\.(gz|bz2|tgz|zip|rar|rz|xz|ps|pdf|rtf|odt|ods)/  and next;
            /\.(png|jpg|gif|xpm)/  and next;

            open IN, $file  or  print("$file $!\n"), next;
            binmode IN;
            $_ = join qq(), <IN>;
            close IN;
            s/\cM//g;
            open OUT, "> $file" or print("$file $!\n"), next;
            binmode OUT;
            print OUT $_;
            close OUT;
        }
    ' "$@"
}

function CygbuildFileConvertEolWhitespace()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if [ $# -eq 0 ]; then
        CygbuildWarn "$id: [ERROR] Argument list \$* is empty"
        return 1
    fi
}

function CygbuildTreeSymlinkCopy()
{
    #   Make symbolic links from FROM => TO

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local from="$1"
    local to="$2"

    CygbuildExitIfNoDir "$from" "$id: [ERROR] parameter failure 'from' $from"

    if [ ! "$to" ]; then
        CygbuildDie "$to" "$id: [ERROR] parameter 'to' is empty"
    fi

    if [ ! -d "$to" ]; then
        mkdir --parents "$to" || exit 1
    fi

    #   cp -lr might do the same as 'lndir'. 'lndir' is widely
    #   regarded as best cross platform solution.

    local LNDIR

    CygbuildWhich lndir > $retval
    [ -s $retval ] && LNDIR=$(< $retval)

    if [ "$LNDIR" ]; then
        LNDIR="$LNDIR -silent"
    else
        CygbuildDie "$id: 'lndir' not found in PATH. Cannot shadow sources."
    fi

    #   lndir(1) cannot be used directly, because we are copying UNDER
    #   the current directory .build; it would cause recursive copying.
    #
    #   So, first copy top level manually, an then let lndir copy
    #   subdirectories.

    CygbuildPushd

        cd "$from" || return 1

        #   Remove all *.exe files before shadowing (they should be generated
        #   anyway.

        CygbuildFindDo .            \
            -o -type f '('          \
                -name "*.exe"       \
                -o -name "*.dll"    \
                -o -name "*.dll.a"  \
                -o -name "*.s[ao]"  \
                -o -name "*.la"     \
                ')'                 \
            > $retval

        if [ -s $retval ]; then
            local file done

            while read file
            do
                if [ "$verbose" ] && [ ! "$done" ]; then
                    CygbuildEcho "-- Cleaning offending files before shadow"
                    done="yes"
                fi

                rm --force $verbose "$file"
            done < $retval
        fi

        local current=$(pwd)
        local dest

        for item in * .*
        do
            if [[ "$item" =~ $CYGBUILD_SHADOW_TOPLEVEL_IGNORE ]]; then
                CygbuildVerb "-- Ignored $item"
                continue
            fi

            dest="$to/$item"

            #   lndir(1) cannot link files that have the same name as
            #   executables, like:
            #
            #       lndir dir/ to/
            #
            #       dir/program
            #       dir/program.exe     =>  to/program.exe
            #
            #   The "program" without ".exe" is not copied. This may
            #   be due to Windows environment.

            if [ -f "$item" ]; then

                if  [ ! -f "$dest" ]; then

                    # [ "$verbose" ] && echo "   $item"

                    ln "$current/$item"  "$dest" || exit 1
                fi

            elif [ -d "$item" ]; then

                if [ ! -d "$dest" ]; then
                    mkdir --parents "$dest"                 || exit 1

                    # [ "$verbose" ] && echo "   $LNDIR $item"

                    $LNDIR "$current/$item" "$dest"
                fi

            else
                item="$(pwd)/$item"
                echo ""
                ls -l "$item"
                CygbuildDie "$id: Don't know what to do with $item"
            fi

        done

    CygbuildPopd
}

function CygbuildFileReadOptionsFromFile()
{
    #   Ignore empty lines and comment lines. Read all others
    #   as one BIG line.

    awk \
    '
        {
            gsub("[ \t]+#.*","");
        }
        ! /^[ \t]*#/ && ! /^[ \t]*$/ {
            str = str " " $0;
        }
        END {
            print str;
        }
    ' ${1:-/dev/null}
}

function CygbuildFileReadOptionsMaybe()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"
    local msg="$2"
    local str

    if [ -f "$file" ]; then

        CygbuildFileReadOptionsFromFile "$file" > $retval

        [ -s $retval ] || return 0

        str=$(< $retval)

        if [ ! "$msg" ]; then
            CygbuildWarn "-- Reading external:" \
                         "${file#$srcdir/}: $str"
        else
            CygbuildWarn "$msg"
        fi
    fi

    echo $str
}

#######################################################################
#
#       Core functions: Define globals and do checks
#
#######################################################################

function CygbuildDefineGlobalCommands()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    BASHX="/bin/bash -x"                            # global-def
    GREP="grep --binary-files=without-match"        # global-def
    EGREP="$GREP --extended-regexp"                 # global-def

    # ................................................. interpreters ...
    #   Official locations under Cygwin. Used to check proper shebang line
    #   Note: /usr/bin in Cygwin is just a mount link to /bin

    local prefix=/bin

    PERLBIN="$prefix/perl"                          # global-def
    PYTHONBIN="$prefix/python"                      # global-def
    RUBYBIN="$prefix/ruby"                          # global-def

    # ............................................ optional features ...

    STAT=                                           # global-def
    CygbuildPathBinFast stat > $retval
    [ -s $retval ] && STAT=$(< $retval)

    CYGCHECK=
    CygbuildWhich cygcheck > $retval
    [ -s $retval ] && CYGCHECK=$(< $retval)         # global-def

    GPG=                                            # global-def
    CygbuildPathBinFast gpg > $retval

    if [ -s $retval ]; then
        GPG=$(< $retval)

        GPGOPT="\
  --no-permission-warning\
  --no-secmem-warning\
  --no-require-secmem
  --no-mdc-warning"

    fi

    WGET=                                           # global-def
    CygbuildPathBinFast wget > $retval
    [ -s $retval ] && WGET=$(< $retval)

    # ......................................................... perl ...

    CygbuildPathBinFast perl > $retval
    [ -s $retval ] && tmp=$(< $retval)

    if [ ! "$tmp" ]; then
        CygbuildDie "-- [FATAL] 'perl' not found in PATH"
    fi

    PERL_PATH="$tmp"
    CygbuildDefineGlobalPerlVersion

    # ....................................................... python ...

    CygbuildPathBinFast python > $retval
    [ -s $retval ] && tmp=$(< $retval)

    if [ ! "$tmp" ]; then
        CygbuildDie "-- [FATAL] 'python' not found in PATH"
    fi

    PYTHON_PATH="$tmp"                              # global-def

    CygbuildDefineGlobalPythonVersion

    local minor=$PYTHON_VERSION                     # global-def

    if [[ "$minor" == *.*.* ]]; then                # 2.5.1
        minor=${minor%.*}
    fi

    local tmp=/usr/lib/python$minor

    if [ -d $tmp ]; then
        PYTHON_LIBDIR=$tmp/config                   # global-def
    fi

    # ........................................................ other ...

    CygbuildWhichCheck make  || CygbuildDie "[FATAL] $id: make not in PATH"
    CygbuildWhichCheck gcc   || CygbuildDie "[FATAL] $id: gcc not in PATH"
    CygbuildWhichCheck perl  || CygbuildDie "[FATAL] $id: perl not in PATH"
    CygbuildWhichCheck quilt || CygbuildDie "[FATAL] $id: quilt not in PATH"

    CygbuildWhichCheck file ||  CygbuildDie "[FATAL] $id: file(1) not in PATH." \
        "Install package 'file'"
}

function CygbuildIsArchiveScript()
{
    [ "$SCRIPT_VERSION" ] && [ "$SCRIPT_RELEASE" ]
}

function CygbuildDefineGlobalScript()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   If this file is named like foo-2.1-1.sh then this is part of
    #   the source archive. These variables get set during Main()

    SCRIPT_FULLPATH=         # /path/to/foo-2.1-1.sh
    SCRIPT_FILENAME=         # foo-2.1-1.sh
    SCRIPT_PKGVER=           # foo-2.1
    SCRIPT_PACKAGE=          # foo
    SCRIPT_VERSION=          # 2.1
    SCRIPT_RELEASE=          # 1

    CygbuildBuildScriptPath  > $retval

    if [ ! -s $retval ]; then
        CygbuildWarb "-- [ERROR] Couldn't determine *self* path"
    fi

    local script=$(< $retval)
    SCRIPT_FULLPATH=$script                             # global-def

    #   /this/path/package-1.1-2.sh  => package-1.1

    local scriptname=${script##*/}
    SCRIPT_FILENAME=$scriptname                         # global-def
    scriptname=${scriptname%.sh}

    CygbuildVersionInfo "$scriptname" > $retval

    [ -s $retval ] || return 0

    local -a arr
    arr=( $(< $retval) )
    local dummy="${arr[*]}"  #  For debugging

    local release=${arr[2]}

    if CygbuildIsNumber "$release" ; then
        SCRIPT_RELEASE=$release                         # global-def

        SCRIPT_PACKAGE=${arr[0]}                        # global-def
        SCRIPT_VERSION=${arr[1]}                        # global-def
        SCRIPT_PKGVER=${arr[0]}-${arr[1]}               # global-def

        #  Make command "./<package>-N.N.sh all" generated result
        #  files to $TOPDIR

        OPTION_GBS_COMPAT="script-N-N"                  # global-def
    fi
}

function CygbuildDefineEnvClear()
{
    CygbuildVerb \
      "-- [INFO] Clearing env: compilation variables like CFLAGS etc."

    #  Do not use environment settings. Only those in Makefiles
    #  or if explicitly set through CYGBUILD_* variables or in the build
    #  scripts.

    CXXFLAGS=
    CFLAGS=
    LDFLAGS=
    INCLUDE_PATH=
    unset CXXFLAGS CFLAGS LDFLAGS INCLUDE_PATH
}

function CygbuildDefineGlobalCompile()
{
    #   Define global variables for compilation

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local make

    CygbuildMakefileName \
        "$srcdir" \
        Makefile.in \
        Makefile.am \
        > $retval &&

    make=$(< $retval)

    local libtool libtoolCompile

    if [ "$make" ] && PackageUsesLibtoolMain $make configure
    then
        libtool="libtool"

        if PackageUsesLibtoolCompile $make ; then
            libtoolCompile="libtool"
        fi
    fi

    if [ "$libtool" ]; then
        CygbuildVerb "-- [INFO] Package seems to use libtool"
    fi

    if [ "$libtool" ] ; then
        #  Read about no-undefined at
        #  http://sourceware.org/autobook/autobook/autobook_88.html

        if [ "$CYGBUILD_LDFLAGS" ]; then
            CYGBUILD_LDFLAGS="-Wl,--no-undefined $CYGBUILD_LDFLAGS"  # global-def
        else
            CYGBUILD_LDFLAGS="-Wl,--no-undefined"                    # global-def
        fi

        if [ "$CYGBUILD_AM_LDFLAGS" ]; then
            # CYGBUILD_AM_LDFLAGS  global-def
            CYGBUILD_AM_LDFLAGS="-Wl,--no-undefined $CYGBUILD_AM_LDFLAGS"
        else
            CYGBUILD_AM_LDFLAGS="-Wl,--no-undefined"                 # global-def
        fi

    fi

    CYGBUILD_CC="gcc"                                           # global-def
    CYGBUILD_CXX="g++"                                          # global-def

    if [ -x /usr/bin/ccache ]; then

        if [ "$libtool" ]; then

            #   ccache can only be used, if Makefile is well contructed for
            #   libtool. That is, is uses --mode=compile for everything.
            #   But we cannot know for sure, so let user decide.

            if [ "$libtoolCompile" ] ; then
                CygbuildVerb "-- Makefile uses libtool and --mode=compile"

                if [[ ! "$CYGBUILD_CC" == *ccache* ]]; then
                    CygbuildVerb "-- you could try" \
                         "CYGBUILD_CC='ccache gcc'"
                fi
            fi
        else
            local msg
            msg="-- [INFO] Using ccache for CC environment variable"

            CYGBUILD_CC="ccache gcc"                        # global-def
            CYGBUILD_CXX="ccache g++"                       # global-def

            CygbuildVerb $msg
        fi
    fi
}

function CygbuildDefineGlobalMain()
{
    #   GLOBAL VARIABLES THAT AFFECT THIS FUNCTION
    #
    #       OPTION_PREFIX_CYGINST       ./.inst  is default
    #       OPTION_PREFIX_CYGBUILD      ./.build is default
    #       OPTION_PREFIX_CYGSINST      ./.sinst is default
    #
    #   Define generic globals. However this has been split to two
    #   functions which define complete set of globas:
    #
    #   CygbuildDefineGlobalMain         This
    #   CygbuildDefineGlobalSrcOrig      And the sister function
    #
    #   The argDirective can have values:
    #
    #       noCheckRelease
    #       noCheckSrc

    # local sourcefile="$OPTION_FILE"

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local argTop="$1"
    local argSrc="$2"
    local argRelease="$3"
    local argPkg="$4"
    local argDirective="$5"

    #   - If filename or explicit release was given
    #   - or examine source directory name package-NN.NN/ name

    local templatepkg=${argPkg:-$argSrc}

    if  [[ "$templatepkg" != *[0-9]*[0-9.]* ]] &&
        [[ "$templaterel" == *[0-9]*[0-9.]* ]]
    then
        templatepkg="$templaterel"      #   Fix it. This is better
    fi

    if  [[ "$templatepkg" != *[0-9]*[0-9.]* ]] &&
        [[ "$argRelease"  == *[0-9]*[0-9.]* ]]
    then
        templatepkg="$argRelease"       #   Fix it. This is better
    fi

    if [[ "$templatepkg" != *[0-9]*[0-9.]* ]]; then

        # Does not look like a correct version, complain
        CygbuildWarn "$id: [WARN] Can't derive VERSION from"        \
             "[$templatepkg]. It is expected that directory name"   \
             "uses format foo-VERSION, like foo-1.2.3. "            \
             "Or perhaps option -f may help."
    fi

    #   Pick any of these, in this order. Variable where
    #   we dig out the version information.

    dummy="A:$release B:$package C:$argSrc"       # For debugging only

    local templaterel=${release:-${package:-$argSrc}}

    CygbuildStrPackage $templatepkg > $retval || exit 1
    local pkgname=$(< $retval)

    CygbuildStrVersion  $templatepkg > $retval || exit 1
    local pkgver=$(< $retval)

    if ! CygbuildIsNumberLike "$pkgver" ; then
        CygbuildWarn "$id: [ERROR] Cannot determine VERSION from $templatepkg"
        CygbuildWarn "$id: [ERROR] Are you inside directory package-N.N/ ?"
        return 1
    fi

    local relver=$templaterel

    if [[ "$relver" == *[!0-9]* ]]; then
        CygbuildStrRelease $relver > $retval || exit 1
        relver=$(< $retval)
    fi

    if [[ "$argDirective" != *noCheckRelease* ]]; then
        if [[ "$relver" != [0-9]* ]] || [ ! $relver -gt 0  ]; then
            # Does not look like a correct version, complain
            CygbuildDie "$id: [ERROR] Can't derive RELEASE from $argSrc." \
                   "See option -r"
        fi
    elif [[ "$relver" != [0-9]* ]]; then
        relver=
    fi

    if [[ "$relver" != [0-9]* ]]; then
        CygbuildWarn "$id: [WARN] RELEASE '$relver' is not a number"
    fi

    CygbuildBuildScriptPath > $retval || exit 1

    BUILD_SCRIPT=$(< $retval)                                   # global-def

    PKG=$(echo $pkgname | tr 'A-Z' 'a-z')                       # global-def
    VER="$pkgver"                                               # global-def
    REL="$relver"                                               # global-def
    FULLPKG="$PKG-$VER-$REL"                                    # global-def

    export prefix="$CYGBUILD_PREFIX"

    # top=${top%/*}

    NAME_PKG_EXT=xz                                             # global-def

    SCRIPT_SRC_PKG_BUILD=$FULLPKG.sh                            # global-def
    NAME_SRC_PKG=$FULLPKG-src.tar.$NAME_PKG_EXT                 # global-def
    NAME_SRC_PATCH=$FULLPKG-cygwin.patch                        # global-def
    NAME_BIN_PKG=$FULLPKG.tar.$NAME_PKG_EXT                     # global-def

    LIBPKG=$PKG                                                 # global-def

    if [[ "$PKG" != lib* ]]; then
        LIBPKG=lib$PKG
    fi

    NAME_LIB_PKG_MAIN=$LIBPKG.tar.$NAME_PKG_EXT                 # global-def

    NAME_PKG_LIB_DEV=$LIBPKG-devel-$VER-$REL.tar.$NAME_PKG_EXT  # global-def
    NAME_PKG_LIB_DOC=$LIBPKG-doc-$VER-$REL.tar.$NAME_PKG_EXT    # global-def
    NAME_PKG_LIB_BIN=$LIBPKG-bin-$VER-$REL.tar.$NAME_PKG_EXT    # global-def

    TOPDIR=$argTop                                              # global-def
    export srcdir=$argSrc

    if [[ ! "$argDirective" == *noCheckSrc* ]] && [ ! -d "$srcdir" ]
    then
        CygbuildDie "$id: SRCDIR doesn't exists: '$srcdir'"
    fi

    #   objdir=${srcdir}/.build
    export objdir=$srcdir

    #   DO NOT CHANGE, .sinst and .inst and other are in fact hard coded
    #   elsewhere too to prevent accidental rm -rf

    if [ "$OPTION_PREFIX_CYGINST" ]; then
        export instdir=$OPTION_PREFIX_CYGINST
    else
        export instdir_relative=".inst"
    fi

    export instdir=$srcdir/$instdir_relative

    if [ "$OPTION_PREFIX_CYGSINST" ]; then
        export srcinstdir=$OPTION_PREFIX_CYGSINST
    else
        export srcinstdir_relative=".sinst"
    fi

    export srcinstdir=$srcdir/$srcinstdir_relative

    #   The .build/ directory is used for various purposes:
    #
    #   1) To compile sources               ./.build/build
    #   2) to make patch against original   ./.build/package-version-orig
    #   3) To make VCS snapshot builds      ./.build/vc

    if [ "$OPTION_PREFIX_CYGBUILD" ]; then
        export builddir_root=$OPTION_PREFIX_CYGBUILD

        builddir_relative_root=${builddir_root##*/}
        export builddir_relative=$builddir_relative_root/build

        export builddir=$OPTION_PREFIX_CYGBUILD/build
    else
        export builddir_relative_root=.build
        export builddir_relative=$builddir_relative_root/build

        export builddir_root=$srcdir/$builddir_relative_root
        export builddir=$srcdir/$builddir_relative
    fi

    export builddir_relative_vc_root=vc
    export builddir_vc_root=$builddir_root/$builddir_relative_vc_root

    PKGLOG=$TOPDIR/${FULLPKG}.log

    # .sinst

    local tmpinst=$srcinstdir

    FILE_SRC_PKG=$tmpinst/$NAME_SRC_PKG                         # global-def

    if CygbuildIsGbsCompat ; then
        CygbuildVerb "-- [NOTE] Using GBS compat mode for" \
                     "source and binary packages"
        FILE_SRC_PKG=$TOPDIR/$NAME_SRC_PKG
    fi

    FILE_SRC_PATCH=$tmpinst/$NAME_SRC_PATCH                     # global-def
    FILE_BIN_PKG=$tmpinst/$NAME_BIN_PKG                         # global-def

    if CygbuildIsGbsCompat ; then
        FILE_BIN_PKG=$TOPDIR/$NAME_BIN_PKG
    fi

    #   Will be defined at runtim

    PATH_PKG_LIB_LIBRARY=$tmpinst/$NAME_LIB_PKG_MAIN            # global-def
    PATH_PKG_LIB_DEV=                                           # global-def
    PATH_PKG_LIB_DOC=                                           # global-def
#    PATH_PKG_LIB_BIN=$tmpinst/$NAME_PKG_LIB_BIN                # global-def


    #   Documentation and setup directories

    local tmpdocdir=$CYGBUILD_DOCDIR_RELATIVE   # _docdir is temp variable

    DIR_CYGPATCH=$srcdir/$CYGBUILD_DIR_CYGPATCH_RELATIVE        # global-def

    CYGPATCH_DONE_PATCHES_FILE=$DIR_CYGPATCH/done-patch.tmp # global-def

    #   user executables

    PATH="$DIR_CYGPATCH:$PATH"                                  # global-def
    CygbuildChmodExec $DIR_CYGPATCH/*.sh

    #   Other files

    SCRIPT_POSTINSTALL_CYGFILE=$DIR_CYGPATCH/postinstall.sh # global-def
    SCRIPT_POSTINSTALL_FILE=$instdir$CYGBUILD_SYSCONFDIR/postinstall # global-def

    #   More global-def

    CYGBUILD_FILE_MANIFEST_DATA=manifest.lst
    CYGBUILD_FILE_MANIFEST_TO=manifest-to.lst
    CYGBUILD_FILE_MANIFEST_FROM=manifest-from.lst

    FILE_PREREMOVE_MANIFEST_FROM=\
$DIR_CYGPATCH/preremove-$CYGBUILD_FILE_MANIFEST_FROM

    FILE_PREREMOVE_MANIFEST_TO=\
$DIR_CYGPATCH/preremove-$CYGBUILD_FILE_MANIFEST_TO

    FILE_POSTINSTALL_MANIFEST_DATA=\
$DIR_CYGPATCH/postinstall-$CYGBUILD_FILE_MANIFEST_DATA

    SCRIPT_PREREMOVE_CYGFILE=$DIR_CYGPATCH/preremove.sh
    DIR_PREREMOVE_CYGWIN=$instdir$CYGBUILD_SYSCONFDIR/preremove
    DIR_POSTINSTALL_CYGWIN=$instdir$CYGBUILD_SYSCONFDIR/postinstall

    DIR_DOC_CYGWIN=$instdir$prefix/$tmpdocdir/Cygwin            # global-def
    DIR_DOC_GENERAL=$instdir$prefix/share/doc/$PKG              # global-def
    DIR_DEFAULTS_GENERAL=$instdir/etc/defaults                  # global-def
    DIR_INFO=$instdir$prefix/share/info                         # global-def

    SCRIPT_PREPARE_CYGFILE=$DIR_CYGPATCH/prepare.sh             # global-def

    EXTRA_CONF_OPTIONS=$DIR_CYGPATCH/configure.options          # global-def
    EXTRA_CONF_ENV_OPTIONS=$DIR_CYGPATCH/configure.env.options  # global-def

    EXTRA_MANDIR_FILE=$DIR_CYGPATCH/mandir                      # global-def
    EXTRA_MANUAL_FILE=$DIR_CYGPATCH/manpages                    # global-def

    EXTRA_BUILD_OPTIONS=$DIR_CYGPATCH/build.options             # global-def
    EXTRA_DIFF_OPTIONS_PATCH=$DIR_CYGPATCH/diff.options         # global-def
    EXTRA_TAR_OPTIONS_INSTALL=$DIR_CYGPATCH/install.tar.options # global-def
    EXTRA_ENV_OPTIONS_INSTALL=$DIR_CYGPATCH/install.env.options # global-def

    SCRIPT_DIFF_BEFORE_CYGFILE=$DIR_CYGPATCH/diff-before.sh     # global-def
    SCRIPT_DIFF_CYGFILE=$DIR_CYGPATCH/diff.sh                   # global-def

    SCRIPT_CONFIGURE_BEFORE_CYGFILE=$DIR_CYGPATCH/configure-before.sh # global-def
    SCRIPT_CONFIGURE_CYGFILE=$DIR_CYGPATCH/configure.sh         # global-def
    SCRIPT_BUILD_CYGFILE=$DIR_CYGPATCH/build.sh                 # global-def
    SCRIPT_CLEAN_CYGFILE=$DIR_CYGPATCH/clean.sh                 # global-def

    FILE_INSTALL_LIB_ABI=$DIR_CYGPATCH/lib.abi                  # global-def
    FILE_INSTALL_MIME=$DIR_CYGPATCH/mime                        # global-def
    FILE_INSTALL_DIRS=$DIR_CYGPATCH/dirs                        # global-def
    FILE_INSTALL_LST=$DIR_CYGPATCH/install.lst                  # global-def
    FILE_DELETE_LST=$DIR_CYGPATCH/delete.lst                    # global-def
    FILE_CONFIG_SUB=$DIR_CYGPATCH/config.sub                    # global-def
    FILE_CONFIG_GUESS=$DIR_CYGPATCH/config.guess                # global-def

    SCRIPT_INSTALL_MAIN_CYGFILE=$DIR_CYGPATCH/install.sh        # global-def
    SCRIPT_INSTALL_MAKE_CYGFILE=$DIR_CYGPATCH/install-make.sh   # global-def
    SCRIPT_INSTALL_AFTER_CYGFILE=$DIR_CYGPATCH/install-after.sh # global-def

    SCRIPT_PATCH_BEFORE=$DIR_CYGPATCH/patch-before.sh           # global-def
    SCRIPT_PATCH_AFTER=$DIR_CYGPATCH/patch-after.sh             # global-def

    SCRIPT_BIN_PACKAGE=$DIR_CYGPATCH/package-bin.sh             # global-def
    SCRIPT_SOURCE_PACKAGE=$DIR_CYGPATCH/package-source.sh       # global-def

    SCRIPT_SOURCE_GET_BASE=source-install.sh                    # global-def
    SCRIPT_SOURCE_GET_TEMPLATE=checkout.sh                      # global-def
    SCRIPT_SOURCE_GET=$srcinstdir/$SCRIPT_SOURCE_GET_BASE       # global-def

    INSTALL_SCRIPT=${CYGBUILD_INSTALL:-"/usr/bin/install"}      # global-def
    INSTALL_FILE_MODES=${INSTALL_DATA:-"--mode=644"}            # global-def
    INSTALL_BIN_MODES=${NSTALL_BIN:-"--mode=755"}               # global-def
}

function CygbuildCygbuildDefineGlobalSrcOrigGuess()
{
    #   Define source package related globals. CygbuildDefineGlobalMain must
    #   have been called prior this function.

    local id="$0.$FUNCNAME"
    local name pkg
    local dummy="pwd $(pwd)"    # for debug

    if [[ "$PACKAGE_NAME_GUESS" == *tar.* ]]; then
        #  The Main function set this variable
        pkg=$PACKAGE_NAME_GUESS
        name=${pkg##*/}     # Delete path
    else
        local ext

        for ext in .tar.gz .tgz .tar.bz2 .tbz2 .tar.lzma .tar.xz
        do

            #  Standard version uses hyphen  : package-NN.NN.tar.gz
            #  Debian version uses underscore: package_NN.NN.tar.gz

            local file try

            for file in $PKG-$VER$ext       \
                        $PKG-$VER-src$ext   \
                        ${PKG}_$VER$ext     \
                        ${PKG}_$VER.orig$ext
            do

                try=$TOPDIR/$file

                if [ -f "$try" ]; then
                    name=$file
                    pkg=$try
                    break 2

                elif [ -h $try ]; then
                    CygbuildWarn "-- [WARN] Dangling symlink found: $TOPDIR"
                    ls -l $try
                fi

            done
        done
    fi

    SRC_ORIG_PKG_NAME="$name"           # global-def
    SRC_ORIG_PKG="$pkg"                 # global-def
}

function CygbuildDefineGlobalSrcOrig()
{
    #   Define Source package related globals.
    #   must have been called prior this function.

    local id="$0.$FUNCNAME"
    local sourcefile="$OPTION_FILE"
    local dummy="$(pwd)"    # for debugging

    if [ ! "$PKG" ] || [ ! "$VER" ]; then
        CygbuildWarn "$id: [FATAL] variables PKG and VER" \
             "are not known. Is current dir package-N.N/ ?"
        return 1
    fi

    if [ -f "$sourcefile" ]; then
        #  If user told where the source file is, then examine that
        local name=${sourcefile##*/}    # Remove path
        SRC_ORIG_PKG_NAME=$name         # global-def
        SRC_ORIG_PKG=$sourcefile        # global-def
    else
        #  Try guessing where that source file is
        if [ ! "$SRC_ORIG_PKG" ]; then
            CygbuildCygbuildDefineGlobalSrcOrigGuess
        fi
    fi

    CygbuildExitIfNoFile "$SRC_ORIG_PKG" \
        "$id: [FATAL] SRC_ORIG_PKG ../$PKG-$VER.tar.gz not found." \
        "Perhaps you have to make a symbolic link from original" \
        "to that file? See manual for details."
}

function CygbuildSrcDirCheck()
{
    #   We must know where the sources are, in orger to run conf, make or
    #   mkpatch etc.

    local id="$0.$FUNCNAME"
    local dir="$1"

    if [ ! "$dir" ]; then
        CygbuildDie "$id: [FATAL] dir is empty"
    fi

    dir=${dir##*/}
    local pkg=${dir%%-*}
    local ver=${dir##*-}

    if  ! CygbuildIsNumberLike "$ver" ; then
        CygbuildWarn "\
$id: [ERROR] Cannot determine plain numeric VERSION (N.N)

The directory $dir
does not look like package-VERSION. Variables cannot be contructed.
You have options:

- chdir to package-NN.NN/ directory and use -f ../package-NN.NN.tar.gz.
  If package name does not have VERSION, and is something like
  foo-latest.tar.gz, make a symbolic link to foo-1.3.tar.gz and try -f again.

- Extract package, and chdir to package-NN.NN/ and try separate
  options: 'mkdirs' 'files' 'conf' 'make'

- If the package does not extract to package-NN.NN/ make a symbolic link
  and chdir into it: ln --symbolic foo3.3alpha3 foo-3.3.1.3; cd  foo-3.3.1.3/

A VERSION must be present either in package name or in directory name"

        exit 0
    fi
}

function CygbuildSrcDirLocation()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    local name=${dir##*/}
    local src="$dir"
    local top

    if [ "$name" = *-$VER       ] ||
         [ -f "$dir/configure"  ] ||
         [ -f "$dir/buildconf"  ] ||
         [ -f "$dir/setup.py"   ] ||
         [ -d "$dir/$CYGBUILD_DIR_CYGPATCH_RELATIVE" ]
    then
        top="$(cd "$dir/.." ; pwd)"

    elif [[    "$top" == *-[0-9]*.*[0-9]
            || "$top" == *-[0-9][0-9][0-9][0-9]*[0-9]
         ]] ; then
        #   Looks like we are inside package-NN.NN/
        top="$(cd "$dir/.." ; pwd)"

    elif [[     $dir == */$CYGBUILD_DIR_CYGPATCH_RELATIVE
             || $dir == */debian
         ]] ; then
        src="$(cd "$dir/.." ; pwd)"
        top="$(cd "$src/.." ; pwd)"

    elif [[ $dir == *.orig ]]; then
        #   Debian uses *.orig directories
        src="$(cd "$src" ; pwd)"
        top="$(cd "$dir/.." ; pwd)"

    else
        top="$(cd "$dir" ; pwd)"
        src="$top"
    fi

    echo "$top" "$src"
}

#######################################################################
#
#       Documentation functions
#
#######################################################################

function CygbuildHelpShort()
{
    local id="$0.$FUNCNAME"
    local exit="$1"

    local bin=$(CygbuildBuildScriptPath)
    bin=${bin##*/}      # Delete path

    echo "
NAME
    cygbuild - Cygwin source and binary package build script

SYNOPSIS
    $bin [option] CMD ...

OPTIONS
    -c, --color            Activate colors
    -d, --debug LEVEL      Debug mode with numeric LEVEL
    -h, --help             Short help. Long help requires full install.
    -r, --release RELEASE  Mandatory option for packaging related commands
    -t, --test             Run in test mode
    -v, --verbose          More verbose messages
    -V, --version          Print version information

    GPG support options

    -s KEY                Sign files with KEY
    -p \"pass phrase\"      Pass phrase. If not given, it is asked from command
                          line.

DESCRIPTION
    Cygbuild is a tool for making, building and maintaining source and
    binary packages under Windows/Cygwin platform. Modeled somewhat after
    the same principles as Debian packaging tool dh_make(1).

    FOR CYGBUILD CONTROLLED INSTALLABLE SOURCE PACKAGE

    Testing the source build
    ------------------------

    If you have downloaded a Cygwin source package, like
    package-N.N-RELEASE-src.tar.xz, it might contain at these files:

        foo-N.N-RELEASE-src.tar.xz
        foo-N.N-RELEASE*.patch
        foo-N.N-RELEASE.sh

    Run the included shell script:

        ./foo-N.N-RELEASE.sh --verbose --color all

    The command 'all' is used for testing the integrity of source
    build and will try to build binary packages. If everything
    succeeds, it runs command 'finish' which removes the unpacked
    source directory.

    Testing the source build - step by step
    ---------------------------------------

    To see the results of source compilation, the commands can be run
    one by one:

        #  Compile from sources
        ./foo-N.N-RELEASE.sh --verbose --color prep conf make install

        #  Verify the installation structure
        cd foo-N.N/
        find .inst/

        #  Remove the test build directory
        cd ..
        rm -rf foo-N.N/

    HOW TO USE CYGBUILD FOR MAKING Cygwin Net Releases

    Full development installation of Cygbuild is needed to develop
    source packages. The CMD can be one of the following. The detailed
    description of each command can be found from the manual page.
    Commands are listed here in order of execution:

        <precondition: cd /to/package/foo-N.N/>

        To prepare port : mkdirs files patch shadow
        To port         : conf build strip
        To install      : install
        To check install: check
        To package      : package source-package
        To sign         : package-sign
        To publish      : publish; copy files to publish area
        All phases      : all
        All, no finish  : almostall

INSTALL INSTRUCTIONS

    Refer to 'Manual' at project page after installation:

$CYGBUILD_INSTALL_INFO

BUGS
    The long --help option consults a separate manual. To read it, a
    full cygbuild installation is needed.

STANDARDS
    For more information about porting guidelines for Cygwin, see
    <http://cygwin.com/setup.html>.

AUTHOR
    Copyright (C) $CYGBUILD_AUTHOR
    License:  $CYGBUILD_LICENSE
    Version:  $CYGBUILD_VERSION
    Homepage: $CYGBUILD_HOMEPAGE_URL"

    [ "$exit" ] && exit $exit
}

function CygbuildHelpLong()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local exit="$1"

    [ ! "$CYGBUILD_STATIC_PERL_MODULE" ] &&
    CygbuildBootVariablesGlobalShareMain

    local lib="$CYGBUILD_STATIC_PERL_MODULE"

    if [ "$lib" ] && [ -f "$lib" ]; then
        perl $lib help
        [ "$exit" ] && exit $exit
    else
        CygbuildHelpShort
        CygbuildWarn "[WARN] No standard manual page available." \
             "Possibly not a full installation of $CYGBUILD_HOMEPAGE_URL"
        exit $exit
    fi
}

function CygbuildHelpSourcePackage()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local lib="$CYGBUILD_STATIC_PERL_MODULE"

    [ "$lib" ] && [ -f "$lib" ] && return 0

    CygbuildEcho "-- [NOTE] Not attempting to make a source package." \
         "Full project is needed" \
         "<$CYGBUILD_HOMEPAGE_URL>."

    return 1
}

#######################################################################
#
#       Misc functions
#
#######################################################################


function CygbuildCompressTarOpt()
{
    if [ "$OPTION_COMPRESS" = "bzip2" ]; then
        echo "--bzip2"
    elif [ "$OPTION_COMPRESS" = "lzma" ]; then
        echo "--lzma"
    elif [ "$OPTION_COMPRESS" = "xz" ]; then
        echo "--xz"
    else
        echo "--gzip"
    fi
}

function CygbuildCompress()
{
    if [ "$OPTION_COMPRESS" = "bzip2" ]; then
        bzip2 "$@"
    elif [ "$OPTION_COMPRESS" = "lzma" ]; then
        lzma "$@"
    elif [ "$OPTION_COMPRESS" = "xz" ]; then
        xz "$@"
    else
        gzip "$@"
    fi
}

function CygbuildCompressManualPage()
{
    # man(1) does not support lzma yet

    if [ "$OPTION_COMPRESS" = "bzip2" ]; then
        bzip2 "$@"
#    elif [ "$OPTION_COMPRESS" = "lzma" ]; then
#        lzma "$@"
    else
        gzip "$@"
    fi
}

function CygbuildNoticeCygwinPatches()
{
    local id="$0.$FUNCNAME"

    cat << EOF
It appears that there is no directory
$DIR_CYGPATCH

The directory should at minimum include files 'package.README' and
'setup.hint'. Files must be in place before binary package can be made.

You can generate template files with command [files].
EOF
}

function CygbuildNoticeMaybe()
{
    local id="$0.$FUNCNAME"

    if [ ! -d "$DIR_CYGPATCH" ]; then
        CygbuildNoticeCygwinPatches
    fi
}

function CygbuildNoticeBuilddirMaybe()
{
    if ! CygbuildIsBuilddirOk ; then
        CygbuildWarn "-- [ERROR] Builddir not ready." \
            "Run command 'shadow'."
        return 1
    fi
}

function CygbuildFileCleanNow()
{
    local id="$0.$FUNCNAME"
    local msg="$1"
    local files="$2"

    local file done

    for file in $files
    do
        if [ ! $done ] &&  [ "$msg" ] ; then
            CygbuildVerb "$msg"
            done=1
        fi

        if [ -f "$file" ]; then
            rm $verbose -f "$file"
        fi
    done
}

function CygbuildFileCleanTemp()
{
    local id="$0.$FUNCNAME"

    if [ "$CYGBUILD_RETVAL" ]; then
        #  cygbuild.sh.tmp.3496.CygbuildTarDirectory.dir
        #  => cygbuild.sh.tmp.[0-9]*.*
        rm --force ${CYGBUILD_RETVAL%.*}.[0-9]* 2> /dev/null
    fi
}

function CygbuildFileExists()
{
    local id="$0.$FUNCNAME"
    local file="$1"

    shift
    local dest dir
    local status=1

    for dir in $*
    do
        from="$dir/$file"

        [ ! -f "$from" ] && continue

        echo "$from"
        status=0
        break
    done

    return $status
}

function CygbuildCygDirCheck()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   Make sure there is a README in /usr/share/doc/Cygwin/

    CygbuildExitIfNoDir "$DIR_DOC_CYGWIN"  "$id: [ERROR] no $DIR_DOC_CYGWIN" \
              "Did forget to run [files] before [install]?"

    local readme
    ls $DIR_DOC_CYGWIN/*.README > $retval 2> /dev/null &&
    readme=$(< $retval)

    if [ ! "$readme" ]; then
        CygbuildDie "$id: [ERROR] no $DIR_DOC_CYGWIN/package.README; " \
               "Did forget to run [files]'?"
    fi

    # sed command trims the leading part of /path/to/.inst => .inst

    $EGREP --line-number --regexp='[<](PKG|VER|REL)[>]' $readme /dev/null |
    sed "s,^.*\$instdir_relative,$instdir_relative,"

    if [ "$?" = "0" ]; then
        CygbuildWarn \
            "-- [WARN] $DIR_DOC_CYGWIN/package.README contains tags." \
            "Edit, use [readmefix] and run [install]"
    fi
}

#######################################################################
#
#       GPG functions
#
#######################################################################

function CygbuildGPGavailableCheck()
{
    if [ "$GPG" ] && [ -x "$GPG" ]; then
        return 0
    fi

    return 1
}

function CygbuildNoticeGPG()
{
    if [ ! "$OPTION_SIGN" ]; then
         if CygbuildGPGavailableCheck ; then
            CygbuildEcho "-- [INFO] gpg available." \
                "You should use package signing (-s)"
        fi
    fi
}

function CygbuildNoticeDevel()
{
    local cmd="$1"

    if [[ "$PACKAGE" == lib* ]]; then
        CygbuildWarn "-- [WARN] Libraries should use command: package-$cmd"
    fi
}

function CygbuildSignCleanAllMaybe()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local sigext=$CYGBUILD_GPG_SIGN_EXT

    #   If signing option is not on, clean old sign files.

    if [ ! "$OPTION_SIGN" ]; then
        if find -L $dir -name "*.$sigext" > $retval ; then
            CygbuildFileCleanNow                \
                "-- Removing old *.$sigext files"
                "$(< $retval)"
        fi
    fi
}

function CygbuildGPGverify()
{
    #   Verify list of signature files. The original files are same,
    #   but .sig extension removed.

    local id="$0.$FUNCNAME"
    local tmp=$CYGBUILD_RETVAL.$FUNCNAME

    local quiet="$1"
    shift

    local status=0
    local sigext=$CYGBUILD_GPG_SIGN_EXT
    local file

    for file in "$@"
    do
        [ ! -f "$file" ]  && continue
        [ ! "$quiet"   ]  && CygbuildEcho "-- Verifying using $file"

        file=${file%$sigext}

        [ ! -f "$file" ]  && CygbuildWarn "-- [WARN] No file found $file"

        #   gpg: WARNING: using insecure memory!
        #   gpg: please see http://www.gnupg.org/faq.html for more information

        $GPG $GPGOPT                                            \
            --verify                                            \
            $file$sigext $file 2>&1                             |
            $EGREP --invert-match 'insecure memory|faq.html'    \
            > $tmp

        status=$?

        if [ "$quiet" == real-quiet ]; then
            CygbuildGrepCheck "Good.*signature" $tmp
            status=$?
        elif [ "$quiet" ]; then
            $EGREP --ignore-case "(Good|bad).*signature" $tmp
        else
            cat $tmp
        fi

    done

    return $status
}

function CygbuildGPGsignFiles()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local signkey="$1"
    local passphrase="$2"
    shift 2

    [ ! "$signkey" ] && return
    [ $# -eq 0     ] && return

    if ! CygbuildGPGavailableCheck ; then
        CygbuildWarn "-- [WARN] gpg not in PATH, cannot sign"
        return 0
    fi

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    date '+%Y-%m-%d %H:%M' > $retval
    local time=$(< $retval)

    local STATUS=0
    local sigext=$CYGBUILD_GPG_SIGN_EXT
    local file sigfile name status

    for file in "$@"
    do
        CygbuildEcho "-- Signing with key [$signkey] file ${file#$srcdir/}"

        sigfile="$file$sigext"

        [ -f "$sigfile" ] && rm --force "$sigfile" 2> /dev/null

        name=${file##*/}

        if [ "$passphrase" ]; then

            echo "$passphrase" |                            \
            $GPG $GPGOPT                                    \
                --verbose                                   \
                --no-tty                                    \
                --batch                                     \
                --passphrase-fd 0                           \
                --detach-sign                               \
                --armor                                     \
                --local-user    "$signkey"                  \
                --output        $sigfile                    \
                --comment "GPG signature of $name ($time)"  \
                $file > $retval 2>&1

                status=$?

        else

            $GPG $GPGOPT                                    \
                --no-batch                                  \
                --detach-sign                               \
                --armor                                     \
                --local-user    "$signkey"                  \
                --output        $sigfile                    \
                --comment "GPG signature of $name ($time)"  \
                $file > $retval 2>&1

                status=$?
        fi

        local display

        [ "$verbose" ] && display="display"

        if [ "$status" != "0" ]; then
            STATUS=$status
            CygbuildWarn "-- [WARN] signing note: ${file##*/}"
            display="display"

            # gpg: can't lock memory: Permission denied

            if grep -qEi 'lock memory' $retval ; then
                STATUS=0
            fi
        fi

        [ "$display" ] && cat $retval

    done

    return $STATUS
}

function CygbuildGPGsignFileOne()
{
    local id="$0.$FUNCNAME"
    local signkey="$1"
    local passphrase="$2"
    local file="$3"

    if [ ! "$signkey" ]; then
        CygbuildDie "$id: [FATAL] No argument: signkey"
    fi

    if [ ! "$file" ]; then
        echo "$id: [FATAL] No argument: file"
    fi

    if [ ! -f "$file" ]; then
        CygbuildEcho "-- Nothing to sign, not found: $file"
    fi

    CygbuildGPGsignFiles "$signkey" "$passphrase" $file
}

function CygbuildGPGsignFileNow()
{
    local id="$0.$FUNCNAME"
    local file="$1"

    local signkey="$OPTION_SIGN"
    local passphrase="$OPTION_PASSPHRASE"

    if [ ! "$signkey" ]; then
        return
    fi

    CygbuildGPGsignFileOne "$signkey" "$passphrase" $file
}

function CygbuildGPGsignMain()
{
    local id="$0.$FUNCNAME"
    local retval=$FUNCNAME.$CYGBUILD_RETVAL
    local sigext=$CYGBUILD_GPG_SIGN_EXT

    local signkey="$1"
    local passphrase="$2"

    if [ ! "$signkey" ]; then
        CygbuildDie "$id: [FATAL] No sign argument: signkey"
    fi

    set -o noglob

        local files
        find -L $srcinstdir                 \
            -type f                         \
            '(' -name "$PKG-$VER-$REL*"     \
                -a \! -name "*$sigext"      \
            ')'                             \
            > $retval

            [ -s $retval ] && files=$(< $retval)

    set +o noglob

    CygbuildGPGsignFiles "$signkey" "$passphrase" $files
}

function CygbuildGPGsignatureCheck()
{
    # Check if there are any *.sig files and check them

    local id="$0.$FUNCNAME"
    local list="$*"

    if [ ! "$list" ]; then
        return
    fi

    if ! CygbuildGPGavailableCheck ; then
        CygbuildVerb "-- No gpg in PATH. Signature checks skipped."
        return
    fi

    local STATUS=0
    local status=0
    local quiet="quiet"
    local file

    [ "$verbose" ] && quiet=""

    for file in $list
    do
        CygbuildGPGverify "$quiet" "$file"
        status=$?

        if [ "$status" != "0" ]; then
            STATUS=$status
        fi
    done

    return $STATUS
}

function CygbuildCmdGPGSignMain()
{
    local id="$0.$FUNCNAME"
    local signkey="$1"
    local passphrase="$2"

    if ! CygbuildGPGavailableCheck ; then
        CygbuildEcho "-- Signing..."
        return
    fi

    if [ ! "$signkey" ]; then
        CygbuildEcho "-- [ERROR] signkey not available. Signing cancelled."
        return
    fi

    if ! CygbuildGPGavailableCheck ; then
        CygbuildEcho "-- [INFO] gpg binary not found. Signing skipped."
        return
    fi

    local status=0
    local file

    for file in \
        $FILE_SRC_PKG \
        $FILE_BIN_PKG \
        $PATH_PKG_LIB_DEV \
        $PATH_PKG_LIB_DOC \
        $PATH_PKG_LIB_BIN
    do
        if [ -f "$file" ]; then
            CygbuildGPGsignFiles "$signkey" "$passphrase" "$file"

            if [ "$?" != "0" ]; then
                status=$?
            fi
        else
            CygbuildVerb "-- Skipped, not exist $file"
        fi
    done

    return $status;
}

function CygbuildCmdGPGVerifyMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local interactive="$1"
    local sigext=$CYGBUILD_GPG_SIGN_EXT
    local force="$OPTION_FORCE"

    #   Are we a "build script"  or "cygbuild.sh" ?
    #   That is, is this unpacked source package case or development
    #   of foo-N.NN/

    local list
    local dir=$(pwd)

    if [[ "$0" == *[0-9]* ]]; then
        ls $PKG*$sigext > $retval 2> /dev/null
        list="$(< $retval)"
    else
        dir="$srcinstdir"
        find $dir -name "$PKG*$sigext" > $retval
        list="$(< $retval)"
    fi

    if [ ! "$list" ]; then
        return 0
    fi

    CygbuildEcho "== Verifying signatures in $dir"

    local status=0

    if ! CygbuildGPGsignatureCheck $list ; then
        [ "$force" ] || CygbuildWarn "-- [WARN] Possible poblem with checking signature(s)."
    fi

    return $status
}

#######################################################################
#
#       Publish functions
#
#######################################################################

function CygbuildCmdAutotool()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    # Run this to re-autotool AFTER editing configure.{ac,in}/Makefile.am

    CygbuildPushd
        cd "$srcdir" &&
        /usr/bin/autoreconf --install --force --verbose
# FIXME: unused code
#        cd "$TOPDIR" &&
#        if [ -f "$PV/INSTALL" ] ; then \
#                unpack ${src_orig_pkg} ${PV}/INSTALL ; \
#        fi
    CygbuildPopd
}

function CygbuildReadmeReleaseMatchCheck()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local file

    if CygbuildDetermineReadmeFile > $retval ; then
        file=$(< $retval)
    else
#        CygbuildWarn "-- [NOTE] Not found $DIR_CYGPATCH/$PKG.README"
        return 1
    fi

    # extract line: ----- version 3.5-2 -----
    # extract line: ----- version package-name-3.5-2 -----
    # where 3.5-2 => "3.5 2" => "2"
    # where 0.4.0-test5-1 => "0.4.0-test5" "1"

    local -a arr=( $(
        awk ' /^--.*version / {
            gsub("^.*version[ \t]+[-_.a-zA-Z]*","");
            ver = $1;
            i = split(ver, arr, /-/);
            if ( i == 2 )
              print arr[1] " " arr[2];
            else if ( i == 3)
              print arr[1] "-" arr[2] " " arr[3];
            exit;
         }' $file
    ))

    local ver=${arr[0]}
    local rel=${arr[1]}

    if [ "$rel" != "$REL" ]; then
        CygbuildWarn "-- [WARN] release $REL mismatch: $ver-$rel" \
                     "in ${file#$srcdir/}"
    fi
}

CygbuildCmdPerlModuleCall()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local module="$CYGBUILD_STATIC_PERL_MODULE"
    local function="$1"
    local command="$2"

    if [ ! "$module" ]; then
        CygbuildWarn "$id: [ERROR] Perl module not found"
        return 1                # Error is already displayed
    fi

    #   1. Load library MODULE
    #   2. Call function Readmefix() with parameters. It will handle the
    #      text manipulation details.

    CygbuildVerb "-- Calling $module::$function"

    local debug=${OPTION_DEBUG:-0}

    perl -e "require qq($module);  SetDebug($debug); $command"
}

function CygbuildCmdFixFilesOther()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$CYGBUILD_DIR_CYGPATCH_RELATIVE"

    #   Because CygbuildFindDo excludes $dir, we must use trick to
    #   cd there first and then restore filenames with sed.
    #
    #   FIXME: Note: directory debian/ is included too, but it only contains
    #   patches.

    CygbuildPushd
        cd "$dir" &&
        CygbuildFindDo ". -maxdepth 1"  \
            -o -type f                  \
            '('                         \
                ! -name "*.diff"        \
                -a ! -name "*.patch"    \
                -a ! -name "*.tmp"      \
            ')'                         |
        sed "s,^\.,$dir,"               |
        sort > $retval.list
    CygbuildPopd

    [ -s $retval.list ] || return 0

    [ "$verbose" ] && cat $retval.list

    local list=$(< $retval.list)

    CygbuildCmdPerlModuleCall "FileFix" \
        "FileFix(qq(split), qq($list));"
}

function CygbuildCmdFixFilesAnnounce()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$CYGBUILD_DIR_CYGPATCH_RELATIVE"
    local file tmp

    for tmp in $dir/*.mail
    do
        if [ -f "$tmp" ] ; then
            file="$tmp"
        fi
    done

    if [ ! "$file" ]; then
        CygbuildVerbWarn "-- [WARN] Cannot update announcement (none found)"
        return 0;
    fi

    CygbuildCmdPerlModuleCall "UpdateAnnouncement" \
        "UpdateAnnouncement(qq($file), qq($PKG), qq($VER), qq($REL));"

}

function CygbuildCmdFixFilesReadme()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    CygbuildDetermineReadmeFile > $retval

    if [ ! -s $retval ]; then
        CygbuildWarn "-- [ERROR] Not found $DIR_CYGPATCH/$PKG.README"
        return 0
    fi

    local readme=$(< $retval)
    CygbuildVerb "-- Check ${readme#$srcdir/}"

    CygbuildCmdPerlModuleCall "ReadmeFix" \
        "ReadmeFix(qq($readme), qq($PKG), qq($VER), qq($REL));"
}

function CygbuildCmdReadmeFixMain()
{
    CygbuildEcho "== Readmefix command"
    CygbuildCmdFixFilesReadme
    CygbuildCmdFixFilesAnnounce
    CygbuildCmdFixFilesOther
}

function CygbuildCmdPublishSetupFix()
{
    local id="$0.$FUNCNAME"
    local dest="$CYGBUILD_PUBLISH_DIR/$PKG"

    [ "$PKG" ] && dest="$dest/$PKG"

    if [ ! "$dest" ] || [ ! -d "$dest" ]; then
        return
    fi

    #  Rename setup files

    local to dir file suffix base

    for dir in $dest/devel $dest/doc $dest/bin
    do
        if [ -d "$dir" ]; then

            suffix=${dir##*/}
            base="setup-$suffix.hint"
            file="$dir/$base"
            to="$dir/setup.hint"

            if [ -f "$file" ]; then
                mv "$file" "$to"
            fi

            if [ ! -f "$to" ]; then
                CygbuildWarn "-- [WARN] Cannot rename $file => $to"
                CygbuildWarn "-- [WARN] Did you write" \
                    "$CYGBUILD_DIR_CYGPATCH_RELATIVE/$base ?"
            fi
        fi
    done
}

function CygbuildCmdPublishSignature()
{
    local id="$0.$FUNCNAME"
    local file="$1"
    local dest="$2"

    if [ ! -d "$dest" ]; then
        return
    fi

    dest=${dest%/}                              # Delete trailing slash

    local sigext="$CYGBUILD_GPG_SIGN_EXT"
    local sigfile="${file##$pwd/}$sigext"
    local sigfiledest="$dest/$file$sigext"
    local name=${file##*/}

    #   Remove destination signature file, it is always becomes invalid
    #   in publish phase. The new one will be copied there.

    [ -f "$sigfiledest" ] && rm --force "$sigfiledest"

    if [ -f "$sigfile" ] && CygbuildGPGavailableCheck ; then

        local opt="-n"
        [ "$verbose" ] && opt=

        echo $opt "-- Checking sigfile $sigfile... "

        local mode=real-quiet
        [ "$verbose" ] && mode=quiet

        CygbuildGPGverify "$mode" $sigfile

        if [ "$?" = "0" ]; then
            echo "ok."
            cp $verbose "$sigfile" "$dest"
        else
            echo "FAILED! Signature not published."
        fi

    fi
}

function CygbuildCmdPublishToDir()
{
    local id="$0.$FUNCNAME"
    local dest="$1"

    dest=${dest%/}  # Delete possible trailing slash

    CygbuildExitIfNoDir \
        $dest "$id: [ERROR] No dir $dest. Define CYGBUILD_PUBLISH_DIR"

    dest="$dest/$PKG"

    CygbuildEcho "-- Publishing to $dest"

    if [ ! -d "$dest" ]; then
        mkdir $verbose -p "$dest" || return 1
    fi

    #  For library packages, the hierarchy is
    #  base/
    #  base/devel/
    #  base/doc/

    local pwd=$(pwd)
    local ext=$OPTION_COMPRESS
    local file

    for file in $srcinstdir/$PKG-$VER-*tar.$ext         \
                $srcinstdir/$PKG-devel-$VER-*tar.$ext   \
                $srcinstdir/$PKG-doc-$VER-*tar.$ext     \
                $srcinstdir/$PKG-bin-$VER-*tar.$ext     \
                $DIR_CYGPATCH/setup.hint                \
                $DIR_CYGPATCH/setup-devel.hint          \
                $DIR_CYGPATCH/setup-doc.hint            \
                $DIR_CYGPATCH/setup-bin.hint

    do

        [ ! -f "$file" ] && continue

        local to=$dest

        case $file in
            *-devel*)  to=$dest/devel ;;
            *-doc*)    to=$dest/doc   ;;
            *-bin*)    to=$dest/bin   ;;
        esac

        if [ ! -d "$to" ]; then
             mkdir $verbose -p "$to" || return 1
        fi

        CygbuildEcho "-- ${file##*/}"

        cp $verbose "$file" "$to" || return 1
        CygbuildCmdPublishSignature "$file" "$to"

    done

    CygbuildCmdPublishSetupFix
}

function CygbuildCmdPublishExternal()
{
    local id="$0.$FUNCNAME"
    local prg="$1"
    local signer="$2"
    local pass="$3"

    CygbuildEcho "-- Publishing with external:" \
        "$prg $TOPDIR $signer ${pass:+<pass>}"

    CygbuildChmodExec "$prg"
    $prg "$TOPDIR" "$PKG" "$VER" "$REL" "$signer" "$pass"
}

function CygbuildCmdPublishMain()
{
    local id="$0.$FUNCNAME"
    local bin="$CYGBUILD_PUBLISH_BIN"
    local signer="$OPTION_SIGN"
    local pass="$OPTION_PASSPHRASE"

    if [ "$bin" ]; then
        CygbuildCmdPublishExternal "$bin" "$signer" "$pass"
    else
        CygbuildCmdPublishToDir "$CYGBUILD_PUBLISH_DIR"
    fi
}

#######################################################################
#
#       Package functions
#
#######################################################################

function CygbuildConfigureOptionsExtra()
{
    #   Return extra configure options based on package

    local id="$0.$FUNCNAME"
    local opt=""

    if CygbuildIsX11appDefaults ; then
        #  Override /usr/lib for X11 applications
        opt="--libdir=/etc/X11 --with-app-defaults=/etc/X11/app-defaults"
    fi

    echo $opt
}

function CygbuildCmdPkgExternal()
{
    local id="$0.$FUNCNAME"
    local prg=$SCRIPT_BIN_PACKAGE
    local status=0

    CygbuildPushd
        cd "$instdir"

        CygbuildEcho "== Making package [binary] with external:" \
             ${prg#$srcdir/} $PKG $VER $REL

        CygbuildChmodExec $prg
        $prg $PKG $VER $REL $TOPDIR

        status=$?

        if [ "$status" = "0"  ]; then
            CygbuildWarn "$id: [ERROR] Failed create binary package."
        fi
    CygbuildPopd

    return $status
}

function CygbuildCmdPkgDevelStandardDoc()
{
    local id="$0.$FUNCNAME"
    local retval="$1"
    local ext=$OPTION_COMPRESS
    RETVAL=

    if [ ! -d "$instdir" ]; then
        CygbuildWarn "-- [ERROR] No files, use command [install] first."
        return 1
    fi

    CygbuildPushd
        cd "$instdir" || exit $?

        #  Exclude README, FAQ, ChangeLog, License etc.

        find usr/share/doc -type f ! -path "*Cygwin*" |
            $EGREP -v '[A-Z][A-Z]'  |
            $EGREP -vi 'change|license' \
            > $retval.doc

        if [ ! -s $retval.doc ]; then
            CygbuildWarn "-- devel-doc [WARN] No doc files for $pkgdoc"
        else

            local pkg="$LIBPKG-doc.tar.$ext"
            NAME_PKG_LIB_DOC=$pkg                               # global-def
            PATH_PKG_LIB_DOC="$srcinstdir/$pkg"                 # global-def
            local tar=$PATH_PKG_LIB_DOC
            local taropt="$CYGBUILD_TAR_EXCLUDE $verbose $z"
            local group="--group=$CYGBUILD_TAR_GROUP"

            CygbuildEcho "-- devel-doc" ${tar#$srcdir/}

            tar $taropt $group --create --file=$tar $(< $retval.doc) ||
            {
                status=$?
                CygbuildPopd
                return $status
            }

            RETVAL="$tar"
        fi
    CygbuildPopd
}

function CygbuildCmdPkgDevelStandardBin()
{
    local id="$0.$FUNCNAME"
    local retval="$1"
    RETVAL=

    if [ ! -d "$instdir" ]; then
        CygbuildWarn "-- [ERROR] No files, use command [install] first."
        return 1
    fi

    CygbuildPushd
        cd "$instdir" || exit $?

        if [ -s $retval.bin ]; then

            local tar="$FILE_BIN_PKG"

            CygbuildTarOptionCompress $tar > $retval
            local z=$(< $retval)
            local taropt="$CYGBUILD_TAR_EXCLUDE $verbose $z"
            local group="--group=$CYGBUILD_TAR_GROUP"

            CygbuildEcho "-- devel-bin" ${tar#$srcdir/}

            tar $taropt $group --create --file=$tar \
                $(< $retval.bin) $(< $retval.man.bin) ||
            {
                status=$?
                CygbuildPopd
                return $status ;
            }

            RETVAL="$tar"
        fi

    CygbuildPopd
}

function CygbuildCmdPkgDevelStandardAbiVersion()
{
    local file="$FILE_INSTALL_LIB_ABI"

    if [ ! -f "$file" ]; then
        CygbuildDie "[FATAL] Library ABI not set in:" ${file#$srcdir/}
    fi

    local abi=$( awk '{sub(/ +/,"")}   /^[0-9]/{print $1; exit}' $file )

    if [ ! "$abi" ]; then
        CygbuildDie "[FATAL] No number found in:" ${file#$srcdir/}
    fi

    CYGBUILD_LIB_ABI_VERSION=$abi               #global-def

    echo $abi
}

function CygbuildCmdPkgDevelStandardLib()
{
    local id="$0.$FUNCNAME"
    local ext=$OPTION_COMPRESS
    local retval="$1"
    RETVAL=

    if [ ! -d "$instdir" ]; then
        CygbuildWarn "-- [ERROR] No files, use command [install] first."
        return 1
    fi

    local abi=$CYGBUILD_LIB_ABI_VERSION
    [ "$abi" ] || abi=$(CygbuildCmdPkgDevelStandardAbiVersion)

    CygbuildPushd
        cd "$instdir" || exit $?

        find usr \
            -name "*.dll" \
            > $retval.lib

        if [ ! -s $retval.lib ]; then
            CygbuildWarn "-- devel-lib [WARN] No *.dll files"
        else

            # usr/bin/cygfontconfig-1.dll => 1

            local pkg=$(echo $PKG |sed 's/lib//')

            local pkg="$LIBPKG$abi.tar.$ext"
            NAME_LIB_PKG_MAIN=$pkg                              # global-def
            PATH_PKG_LIB_DEV="$srcinstdir/$pkg"                 # global-def

            local tar=$PATH_PKG_LIB_DEV

            CygbuildTarOptionCompress $tar > $retval
            local z=$(< $retval)
            local taropt="$CYGBUILD_TAR_EXCLUDE $verbose $z"
            local group="--group=$CYGBUILD_TAR_GROUP"

            CygbuildEcho "-- devel-lib" ${tar#$srcdir/}

            tar $taropt $group --create --file=$tar $(< $retval.lib) ||
            {
                status=$?
                CygbuildPopd
                return $status ;
            }
        fi

        RETVAL="$tar"
    CygbuildPopd
}

function CygbuildCmdPkgDevelStandardDev()
{
    local id="$0.$FUNCNAME"
    local ext=$OPTION_COMPRESS
    local retval="$1"
    RETVAL=

    if [ ! -d "$instdir" ]; then
        CygbuildWarn "-- [ERROR] No files, use command [install] first."
        return 1
    fi

    local abi=$CYGBUILD_LIB_ABI_VERSION
    [ "$abi" ] || abi=$(CygbuildCmdPkgDevelStandardAbiVersion)

    CygbuildPushd
        cd "$instdir" || exit $?

        cat $retval.bin $retval.man.bin $retval.lib $retval.doc \
            > $retval.already.packaged

        find . -type f > $retval.find

        $EGREP --invert-match --file=$retval.already.packaged \
               $retval.find > $retval.dev

        if [ ! -s $retval.dev ]; then
            CygbuildWarn "-- [devel-dev] [WARN] No *.h or*.a files" \
                "for $pkglib"
        else

            local pkg="$LIBPKG$abi-devel.tar.$ext"
            NAME_LIB_PKG_MAIN=$pkg                              # global-def
            PATH_PKG_LIB_LIBRARY="$srcinstdir/$pkg"             # global-def

            local tar=$PATH_PKG_LIB_LIBRARY

            CygbuildTarOptionCompress $tar > $retval
            local z=$(< $retval)
            local taropt="$CYGBUILD_TAR_EXCLUDE $verbose $z"
            local group="--group=$CYGBUILD_TAR_GROUP"

            CygbuildEcho "-- devel-dev" ${tar#$srcdir/}

            tar $taropt $group --create --file=$tar $(< $retval.dev) ||
            {
                status=$?
                CygbuildPopd
                return $status
            }
        fi

        RETVAL="$tar"
    CygbuildPopd
}

function CygbuildCmdPkgDevelStandardMain()
{
    local id="$0.$FUNCNAME"
    local status=0
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if [ ! -d "$instdir" ]; then
        CygbuildWarn "-- [ERROR] No files, use command [install] first."
        return 1
    fi

    CygbuildPushd

        CygbuildEcho "== Making packages [devel] from" \
                     "${instdir#$srcdir/}"

        cd "$instdir" || exit $?

        #   Prepare all return files
        touch $retval.man.bin $retval.man.others \
              $retval.doc $retval.bin $retval.lib

        # ..................................................... bin ...
        #  Find all executables. Exclude library config like xxx-config

        find usr \
             '(' \
                -path "*/bin/*" \
                -o -path "*/var/*" \
                -o -path "*/etc/*" \
                -o -path "*/sbin/*" \
            ')' \
            -a ! -name "*.dll*" \
            -a ! -name "*.la" \
            -a ! -name "*.a" \
            -a ! -name "*-config" \
            > $retval.bin

        # .................................................. manuals ...

        find usr/share/man -type f > $retval.man.all 2> /dev/null

        if [ -s $retval.bin ]; then

            # Include manual pages for executables

            local manregexp=$(
                awk '
                {
                    gsub(".*/", "");
                    sub("[.](pl|py|exe|sh)$", "");
                    re = re "|" $0;
                }
                END {
                    print substr(re, 2);
                }
                ' $retval.bin
            )

            if [ "$manregexp" ]; then
                find usr/share/man                      \
                    -regextype posix-egrep              \
                    -regex ".*($manregexp)[.][0-9].*"   \
                    -type f                             \
                    >> $retval.man.bin
            fi

            if [ -s $retval.man.bin ]; then
                $EGREP --invert-match --file=$retval.man.bin \
                    $retval.man.all > $retval.man.others
            else
                CygbuildWarn "-- [WARN] No manual pages executables"
                cat $retval.bin
                cp $retval.man.all $retval.man.others
            fi
        fi

        CygbuildCmdPkgDevelStandardDoc "$retval"
        pkgdoc=$RETVAL

        find etc/ usr/share/{doc,locale,emacs,info} \
            -type f \
            >> $retval.bin \
            2> /dev/null

        if [ -s $retval.doc ]; then
            #   If there is doc package, then exclude those files
            mv $retval.bin $retval.bin.tmp

            $EGREP --invert-match --file=$retval.doc \
                $retval.bin.tmp > $retval.bin
        fi

        CygbuildCmdPkgDevelStandardDev "$retval"
        pkgdev=$RETVAL

        CygbuildCmdPkgDevelStandardLib "$retval"
        pkglib=$RETVAL

        CygbuildCmdPkgDevelStandardBin "$retval"
        pkgbin=$RETVAL

    CygbuildPopd

    local file

    for file in $pkgdev $pkglib $pkgbin $pkgdoc
    do
        if [ -f "$file" ]; then
            CygbuildGPGsignFileNow $file
        fi
    done
}

function CygbuildCmdPkgDevelMain()
{
    local id="$0.$FUNCNAME"

    CygbuildCygDirCheck  || return $?

    if [ -f "$SCRIPT_BIN_PACKAGE" ]; then
        CygbuildCmdPkgExternal
    else
        CygbuildCmdPkgDevelStandardMain
    fi
}

function CygbuildCmdPkgBinaryStandard()
{
    local id="$0.$FUNCNAME"
    local status=0
    local tarz=$(CygbuildCompressTarOpt)
    local taropt="$CYGBUILD_TAR_EXCLUDE $verbose $tarz --create --file"
    local sigext=$CYGBUILD_GPG_SIGN_EXT
    local pkg=$FILE_BIN_PKG

    CygbuildEcho "== Making package [binary]" ${pkg#$srcdir/}

    CygbuildExitIfNoDir "$srcinstdir" "$id: [ERROR] no $srcinstdir" \
              "Did you forget to run [mkdirs]?"

    CygbuildFileCleanNow "" $pkg $pkg$sigext

    CygbuildPushd
        cd "$instdir" || exit 1
        tar $taropt "$pkg" *    # must be "*", not "." => would cause ./path/..
        status=$?
    CygbuildPopd

    if [ "$status" = "0" ]; then
        CygbuildGPGsignFileNow $pkg
    fi

    return $status
}

function CygbuildCmdPkgBinaryMain()
{
    local id="$0.$FUNCNAME"

    CygbuildCygDirCheck  || return $?

    if [ -f "$SCRIPT_BIN_PACKAGE" ]; then
        CygbuildCmdPkgExternal
    else
        CygbuildCmdPkgBinaryStandard
    fi
}

CygbuildPackageSourceDirClean()
{
    local id="$0.$FUNCNAME"
    local status=0

    # Clean previous sourcepacakge install and start from fresh.
    # Make sure it looks like .sinst

    if [[ $srcinstdir == *$sinstdir_relative* ]]; then
        CygbuildPushd
            cd "$srcinstdir" && rm --force $PKG*-src*
            status=$?
        CygbuildPopd
    fi
}

function CygbuildPatchLs ()
{
    awk ' /^\+\+\+ / {print $2}' ${1:-/dev/null}
}

function CygbuildPatchApplyRun()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local patchopt="$CYGBUILD_PATCH_OPT"
    local patch="$1"
    shift

    local dummy="Additional options: $@"    # For debug
    local pwd=$(pwd)                        # For debug

    if [ ! "$verbose" ]; then
        patchopt="$patchopt --quiet"
    fi

    #  Cygwin's patch(1) needs --binary option to be able to handle CRLF
    #  diffs correctly.

    if CygbuildIsCygwin; then
        if CygbuildFileIsCRLF "$patch" ; then
            patchopt="$patchopt --binary"
        fi
    fi

    #  The files to be patched must be writable. Sometimes upstream
    #  contains read-only files.

    CygbuildPatchLs "$patch" > $retval

    local dest

    for dest in $(< $retval)
    do
        [ ! -f "$dest" ] && dest=${dest#*/}     # Strip 1
        [ ! -f "$dest" ] && dest=${dest#*/}     # Strip 2
        [ ! -f "$dest" ] && dest=${dest#*/}     # Strip 3

        if [ -f "$dest" ] && [ ! -w "$dest" ]; then
            chmod $verbose +w $dest
        fi
    done

    if [ -f "$patch" ]; then
        if [ "$verbose" ]; then
            dummy="$patchopt $*"
            # Remove excess spaces
            dummy=${dummy//  / }
            dummy=${dummy//  / }
            dummy=${dummy//  / }

            CygbuildEcho "-- cd $pwd && patch $dummy < ${patch#$srcdir/}"
        else
            local msg="Patching"
            [[ "$*" == *\ +(--reverse|-R\ )* ]] && msg="Unpatching"

            CygbuildEcho "-- $msg with ${patch#$srcdir/}"
        fi

        ${test:+echo} patch $patchopt "$@" < $patch
    else
        CygbuildWarn "$id: [ERROR] No Cygwin patch file " \
             "FILE_SRC_PATCH '$FILE_SRC_PATCH'"
        return 1
    fi
}

function CygbuildPatchFileQuilt()
{
    local id="$0.$FUNCNAME"
    local dir=${1:-"$(pwd)/$CYGBUILD_DIR_CYGPATCH_RELATIVE"}

    CygbuildFindLowlevel "$dir"         \
        -a -type d                      \
            '('                         \
                -path "*/tmp*"          \
            ')'                         \
            -prune                      \
            -a ! -name "tmp*"           \
        -o -type f                      \
            -name series                |
    sort
}

function CygbuildPatchFileList()
{
    local id="$0.$FUNCNAME"
    local dir=${1:-"$(pwd)/$CYGBUILD_DIR_CYGPATCH_RELATIVE"}
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ "$dir"    ] || return 1
    [ -d "$dir" ] || return 1

    local file=$retval

    #   See if there are any quilt(1) files and ignore those
    #   directories

   CygbuildPatchFileQuilt  |
        sed 's,/series$,,' \
        > $retval

    if [ ! -s $retval ]; then
        #   Generate fake content, see grep(1) next
        echo "ThisRegexpIsNotMathed" > $retval
    fi

    #   Grep there filters out quilt directories
    #   Disregard files in */tmp/* or /*.tmp/* directories

    find "$dir" -type f -name "*.patch" |
        grep -Ev "/tmp/|/[^/]+\.tmp/" |
        grep -vFf $retval  |
        sort
}

function CygbuildPatchPrefixStripCountFromContent()
{
    local id="$0.$FUNCNAME"
    local file="$1"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   Read the first line in patch that is in format:
    #       +++ path/to/foo-0.11.7.3.1/subdir/code.c
    #
    #   => up till 'foo'

    if ! awk ' /^\+\+\+ / {
                    ok = 1
                    print $2
                    exit
                }
                END {
                    if (!ok)
                        exit(1)
                }
              ' $file > $retval
    then
        CygbuildWarn "-- [WARN] Unrecognized patch format $file"
        return 1
    fi

    local tmp=0
    local saved="$IFS"
    local path=$(< $retval)

    local part=${path#*/}           # dir/this.patch => this.patch

    if [ -f "$path" ]; then
        echo 0
        return 0
    elif [ -f "$part" ]; then
        echo 1
        return 0
    fi

    local prefix1

    if [[ "$path" == b/* ]]; then
        #  Mercurical and Git outputs 'patch -p1' format:
        #   --- a/Makefile.in       Sun Aug 05 20:45:37 2007 +0300
        #   +++ b/Makefile.in       Sun Aug 05 23:55:17 2007 +0300
        prefix1="$path"
    fi

    local count

    #   If PART name match the package name, then that is
    #   the strip count. Typical in: diff -ru ../orig/foo-1.1 foo-1.1

    local IFS="/"
        set -- $path

        if [ $# -gt 1 ]; then
            for part in $*
            do
                tmp=$((tmp + 1))

                if [[ $part == $PKG-*[0-9]* ]] ; then
                    count=$tmp
                    break;
                fi
            done
        fi

    IFS="$saved"

    #  If no PKG was found, then perhaps this is patch generated from VCS

    if [ ! "$count" ] && [ "$prefix1" ] && [ ! -f "$prefix1" ]; then
        count=1
    fi

    if [ "$count" ]; then
        echo $count
    else
        return 1
    fi
}

function CygbuildPatchPrefixStripCountFromFilename()
{
    local id="$0.$FUNCNAME"
    local str=$1

    #   If the filename that contains a hint how much to strip, use it.
    #       CYGWIN/-PATCHES/foo-1.2.3.strip+3.patch

    [[ $str != *strip+*  ]] && return 1

    str=${str##*strip+}
    str=${str%%[!0-9]*}

    if [ "$str" ]; then
        echo $str
    else
        return 1
    fi
}

function CygbuildPatchPrefixStripCountMain ()
{
    local id="$0.$FUNCNAME"
    local file=$1

    CygbuildPatchPrefixStripCountFromFilename "$file"   ||
    CygbuildPatchPrefixStripCountFromContent  "$file"
}

function CygbuildPatchApplyQuiltMaybe()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local cmd="$1"  # {patch,unpatch}[-nostat][-quiet][-force]
    local msg="patch"
    local verb

    local debug
    [[ "$OPTION_DEBUG" > 0 ]] && debug="debug"

    # FIXME: De we need to handle *-force option?

    [ "$verbose"           ] && verb="-v"
    [[ "$cmd" == *-quiet* ]] && verb="-q"

    CygbuildPatchFileQuilt > $retval

    [ -s $retval ] || return 0

    CygbuildWhichCheck quilt ||
    CygbuildDie "[FATAL] $id: Can't handle patches. quilt not in PATH"

    local quilt="quilt push -a"

    if [[ "$cmd" = unpatch* ]]; then
        msg="unpatch"
        quilt="quilt pop -a"
    fi

    local color

    if [[ "$quilt" == *push* ]]; then     # POP does not support color
        if [ "$INSIDE_EMACS" ]; then
            color="--color=never"
        elif [ "$OPTION_COLOR" ]; then
            color="--color=always"        # auto
        fi
    fi

    local series
    local relative=$srcdir/

    while read series
    do
        CygbuildEcho "-- Wait, quilt $msg" ${series#$relative}

        if [ ! -s "$series" ]; then
            CygbuildWarn "-- [WARN] empty quilt control file. Ignored for now."
            continue
        fi

        local dir=${series%/series}
        local log=$retval.quilt

        [ "$debug" ] && set -x

        local dummy=$(pwd)               # For debugging

        CygbuildRun env QUILT_PATCHES=$dir LC_ALL=C $quilt $verb $color \
        2> $log 1>&2

        local status=$?

        [ "$debug" ] && set +x

        if [ "$verbose" ] || [ "$status" != "0" ]; then
            cat $log
        else
            grep -Ev "No patches applied|Now at patch" $log |
            sed "s,$srcdir/,,"
        fi

        if $EGREP --quiet --ignore-case \
           "no patch.*removed|series fully applied|No patches applied" \
           $log
        then
            #   File series fully applied => status code 1
            status=""
        fi

        if tail -1 $log | $EGREP --quiet --ignore-case \
           "Applying patch"
        then
            # Even though patches apply, it still reports ERROR status(1).
            # Perhaps due to "Hunk #1 succeeded" messages?
            status=""
        fi

        rm -f $log

        [ "$status" ] && return $status

    done < $retval

    return 0
}

function CygbuildPatchApplyMaybe()
{

    local id="$0.$FUNCNAME"
    local dir="$DIR_CYGPATCH"
    local statfile="$CYGPATCH_DONE_PATCHES_FILE"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local cmd="$1"  # {patch,unpatch}[-nostat][-quiet][-force]
    local msg="$2"

    [ ! "$cmd" ] && cmd="patch"

    local patch unpatch

    [[ "$cmd" == patch* ]] && patch="patch"
    [[ "$cmd" == unpatch* ]] && unpatch="unpatch"

    local verb="$verbose"
    local statCheck="statCheck"
    local force

    if CygbuildIsGbsCompat ; then
        #   During source package 'all' command turn this on, so that
        #   the patches applied can be seen at glance
        verb="gbs verbose"
    fi

    [[ "$cmd" == *-force*  ]] && force="force"
    [[ "$cmd" == *-quiet*  ]] && unset verb
    [[ "$cmd" == *-nostat* ]] && statCheck=

    # NOTE: The quilt must be run last, if we're unpatching (reverse order)

    if [ "$patch" ]; then
        CygbuildPatchApplyQuiltMaybe $cmd || return $?
    fi

    CygbuildPatchFileList > $retval
    local list

    if [ -s $retval ]; then
        list=$(< $retval)
    fi

    [ "$msg" ] && CygbuildEcho "$msg"

    if [ "$unpatch" ] && [ "$list" ]; then

        if [ ! -f "$statfile" ]; then
            CygbuildEcho "-- [INFO] No" ${statfile#$srcdir/}
            list=""
        else

            local file tmp

            #  reverse the order
            for file in $list
            do
              tmp="$file $tmp"
            done

            list="$tmp"
        fi
    fi

    # FIXME: patch-before.sh

    local file

    for file in $list
    do
        [ -f "$file" ] || continue

        local name=${file#$srcdir\/}
        local grep="$GREP --quiet --ignore-case --fixed-strings"
        local done=
        local continue=
        local record=

        if [ "$statCheck" ]; then
            if [ -f "$statfile" ]; then

                local basename=${name##*/}

                if $grep "$name" "$statfile" ; then
                    record="$name"
                    done=done
                elif [[ "$name" == */* ]] &&
                     $grep "$basename" "$statfile"
                then
                    #   The recorded filename did not contain path
                    done=done
                    record="$basename"
                fi

                if [ "$patch" ] ; then
                    if [ "$done" ]; then

                        [ "$verb" ] &&
                        CygbuildEcho "-- [INFO] Patch already applied: $name"

                        continue="continue"
                    fi
                elif [ ! "$done" ]; then
                    continue                            # Nothing to unpatch
                fi
            fi

            if [ "$force" ]; then
                :       # Keep going
            elif [ "$continue" ]; then
                continue;
            fi
        fi

        local opt

        CygbuildPatchPrefixStripCountMain "$file" > $retval

        local count=0

        if [ -s $retval ]; then
            count=$(< $retval)
            opt="$opt --strip=$count"
        fi

# FIXME: Check CRLF file and use --binary for patch
#       if [ $count -gt 0 ]; then
#
#           local patchfile
#           local i=0
#
#           while [ $i -lt $count ]
#           do
#               i=$((i + 1))
#           done
#       fi

        [ "$unpatch" ] && opt="$opt --reverse"

        if [ ! "$verbose" ]; then
            local msg="Unpatching"
            [ "$patch" ] && msg="Patching"

            CygbuildVerb "-- $msg with" $name
        fi

        CygbuildPatchApplyRun "$file" $opt ||
        {
            CygbuildEcho "-- [NOTE] ...Hm, retrying with option --binary"
            CygbuildPatchApplyRun "$file" $opt --binary ;
        } ||
        CygbuildDie "-- [FATAL] Exiting."

        if [ "$unpatch" ] && [ "$statCheck" ] ; then

            if [ -f "$statfile" ]; then
                #   Remove name from patch list
                $grep --invert-match "$record" "$statfile" > $retval
                mv "$retval" "$statfile"
            fi

            if  [ -f $statfile ] && [ ! -s $statfile ]; then
                rm --force "$statfile"  # Remove empty file
            fi

        else
            echo $name >> $statfile
        fi
    done

    if [ "$unpatch" ]; then
        CygbuildPatchApplyQuiltMaybe $cmd || return $?
    fi
}

function CygbuildCmdMkpatchMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local signkey="$1"
    local passphrase="$2"

    CygbuildDefineGlobalSrcOrig || return 1

    CygbuildIsSrcdirOk \
        "[FATAL] Not recognized; expect package-N[.N]+: $srcdir"

    local status=0
    local sigext=$CYGBUILD_GPG_SIGN_EXT
    local origdir="$builddir_root"
    local origpkgdir="$origdir/$PKG-$VER-orig"
    local out=$FILE_SRC_PATCH

    local destdir=${FILE_SRC_PATCH%/*}

    if [ ! -d "$destdir" ]; then
        CygbuildEcho "-- [ERROR] No destination patch directory." \
                     "Run [mkdirs]: $destdir"
        return 1
    fi

    local diffopt="$CYGBUILD_DIFF_OPTIONS"
    local diffscript=$SCRIPT_DIFF_CYGFILE
    local prescript=$SCRIPT_DIFF_BEFORE_CYGFILE

    local debug
    [[ "$OPTION_DEBUG" > 0 ]] && debug="debug"

    CygbuildEcho "== Making patch" ${out#$srcdir/}

    CygbuildNoticeBuilddirMaybe || return 1

    #   The starting directory structure is:
    #
    #       ROOT/foo.1.12.tar.gz
    #
    #       ROOT/foo-1.12/
    #                   |
    #                   +-.build/build/     $builddir_root
    #                   +-.sinst/
    #                   +-.inst/
    #
    #   1) Extract ROOT/foo.1.12.tar.gz in $builddir_root
    #
    #   2) rename extracted dir ROOT/foo-1.12/.build/build/foo-1.12/
    #      to                   ROOT/foo-1.12/.build/build/foo-1.12-orig/
    #
    #   3) copy (exclude .*) with tar ROOT/foo-1.12 => ROOT/foo-1.12/.build
    #
    #   4) diff -r ROOT/foo-1.12/.build/foo-1.12-orig/
    #              ROOT/foo-1.12/.build/foo-1.12/
    #
    #   NOTE: 'copydir' must be exactly the same name as the 'srcdir'
    #   Otherwise applying the patch will fail.

    local copydir=$builddir_root/${srcdir##*/}
    local file="$SRC_ORIG_PKG"

    CygbuildExitIfNoFile \
        "$file" "$id: [ERROR] Original archive not found $file"

    CygbuildFileReadOptionsMaybe "$EXTRA_DIFF_OPTIONS_PATCH" > $retval
    local extraDiffOpt=$(< $retval)

    if [[ "$extraDiffOpt" == *cygbuild-ignore-all-defaults* ]]; then
        diffopt=""
    fi

    if [ ! "$origpkgdir" ]; then
        #  This may never happen, but check anyway that variable
        #  is not empty.
        CygbuildWarn "$id: [ERROR] variable 'origpkgdir' is empty."
        return 1
    fi

    local cleandir

    (

        # ................................. Extract original package ...

        cd "$origdir" || exit 1

        CygbuildVerb "-- Extracting original $file"

        #   What is the central directory in tar file?

        CygbuildTarDirectory $file > $retval || return $?
        dir=$(< $retval)

        #   Where will we unpack the original archive?

        cd="."

        if [[ ! "$dir"  ]] || [[ "$dir" = "." ]]; then
            #  Hm, sometimes archive does not include subdirectories

            CygbuildVerbWarn \
                "-- [WARN] Original archive does not unpack to a" \
                "separate directory package-N.N. Fixing this. "

            dir="abcxyz"
            cd=$dir

            [ -d "$dir" ] && rm -rf "$dir"
            mkdir "$dir" || return $?

        else
            if [ -d "$dir" ]; then
                rm -rf "$dir" || exit 1
            fi
        fi

        if [ -d "$origpkgdir" ]; then
            rm -rf "$origpkgdir" || exit 1
        fi

        dummy="PWD is $(pwd)"                  # Used for debugging

        tar --directory "$cd" --extract \
            --no-same-owner --no-same-permissions --file "$file" ||
        {
            status=$?
            echo "$id: [ERROR] tar --directory -C $cd -xf $file"
            return $status
        }

        #   Rename by moving to: foo-1.12-orig
        mv "$dir" "$origpkgdir" || return $?

        cd "$srcdir" || exit $?

        cursrcdir="$srcdir"

        # .......................................... Make duplicate? ...

        if [ "$OPTION_SPACE" ]; then

            #   Do not destroy current compilation results, because
            #   recompilation might be very slow with big packages.
            #
            #   Copy the current sources elsewhere and then "clean".
            #   This preserves current sources + compilation.

            cursrcdir="$copydir"
            cleandir="$copydir"

            CygbuildEcho "-- Wait, taking a snapshot (may take a while)..."

            if [ -d "$cursrcdir" ]; then
                rm -rf "$cursrcdir" || exit $?
            fi

            mkdir --parents "$cursrcdir" || exit $?

            dummy="PWD is $(pwd)"           # Used for debugging
            local group="--group=$CYGBUILD_TAR_GROUP"

            tar $CYGBUILD_TAR_EXCLUDE \
                --create $group --file=- . \
                | (
                    cd "$cursrcdir" &&
                    tar --extract \
                        --no-same-owner \
                        --no-same-permissions \
                        --file=-
                  ) \
                || exit 1

            # Copy quilt directory manually; excluded by CYGBUILD_TAR_EXCLUDE

            if [ -d "$srcdir/.pc" ]; then
                cp -r --dereference "$srcdir/.pc" "$cursrcdir"
            fi

            CygbuildEcho "-- Wait, undoing local patches (if any)"

            (
                #   We must not touch the patch status file, because
                #   this is just a temporary unpatching only for during
                #   taking the diff.

                #  Quilt cannot cope with symlinks, so we must
                #  run in srcdir

                cd "$cursrcdir" &&
                CygbuildPatchApplyMaybe unpatch-nostat-quiet-force

            ) || exit 1

        fi

        cd "$cursrcdir" || exit 1

        CygbuildCmdCleanMain     $cursrcdir nomsg
        CygbuildCmdDistcleanMain $cursrcdir nomsg

        difforig=${origpkgdir##$(pwd)/}      # Make relative paths
        diffsrc=${cursrcdir##$(pwd)/}

        if [ -f "$prescript" ]; then
            #   If there is custom script, run it.
            CygbuildEcho "--- Running external prediff:" \
                 "$prescript $difforig $diffsrc"

            CygbuildChmodExec $prescript
            ${OPTION_DEBUG:+$BASHX} $prescript "$difforig" "$diffsrc"
        fi

        if [[ "$extraDiffOpt" != *cygbuild-ignore-autocheck* ]]; then
            CygbuildPatchFindGeneratedFiles "$origpkgdir" "$cursrcdir" \
                "$extraDiffOpt" > $retval || return $?

            exclude="$(< $retval)"
        fi

        topdir=${cursrcdir%/*}               # one directory up

        cd "$topdir" || exit 1

        difforig=${origpkgdir##$(pwd)/}      # Make relative paths
        diffsrc=${cursrcdir##$(pwd)/}

        if  [ ! "$difforig" ] || [ ! -d "$difforig" ]; then
            CygbuildWarn "$id: No orig dir. Snapshot possibly failed: $difforig"
            return 1
        fi

        if  [ ! "$diffsrc" ] || [ ! -d "$diffsrc" ]; then
            CygbuildWarn "$id: No src dir. Snapshot possibly failed: $diffsrc"
            return 1
        fi

        # ............................ Preparation done, take a diff ...

        if [ -f "$diffscript" ]; then
            #   If there is custom script, run it.
            CygbuildEcho "--- Running external diff: $diffscript" \
                 "$difforig $diffsrc $out"

            CygbuildChmodExec $difforig
            ${OPTION_DEBUG:+$BASHX} $diffscript "$difforig" "$diffsrc" "$out"
        else

            local dummy="pwd: $(pwd)"    # For debugging
            local dummy="out: $out"      # For debugging

            TZ=UTC0 diff \
                $diffopt \
                $exclude \
                $extraDiffOpt \
                "$difforig" "$diffsrc" \
                > $out

            status=$?

            echo "-- Patch file " ${out#$srcdir/}

            #   GNU diff(1) return codes are strange.
            #   Number 1 is OK and value > 1 indicates an error

            if [ "$status" != "1" ]; then

                CygbuildWarn "$id: [ERROR] Making patch failed" \
                     "with code $status."                       \
                     "Check ${origpkgdir#$srcdir/} and ${out#$srcdir/}" \
                     "or do you need to run again [shadow]?"

                return $status

            else

                #  Fix Debian original source directories in Patch
                #
                #  --- foo-0.93.3-orig/CYGWIN-PATCHES/catdoc.README
                #  +++ foo-0.93.3.orig/CYGWIN-PATCHES/catdoc.README
                #
                #  =>
                #  --- foo-0.93.3-orig/CYGWIN-PATCHES/catdoc.README
                #  +++ foo-0.93.3/CYGWIN-PATCHES/catdoc.README

                if CygbuildGrepCheck '^\+\+\+ .*\.orig/' $out ; then
                    CygbuildVerb "-- Fixing patch (Debian .orig)"

                    sed 's,^\(+++ .*\).orig\(.*\),\1\2,' $out > $out.tmp &&
                    mv "$out.tmp" "$out"
                fi

                CygbuildVerb "-- Removing" ${origpkgdir#$srcdir/}

                if [ ! "$debug" ]; then
                    rm -rf "$origpkgdir" "$cleandir"
                fi

                #   Signature is no longer valid, remove it.
                sigfile="$out$sigext"

                [ -f "$sigfile" ] && rm --force "$sigfile"

                CygbuildGPGsignFiles "$signkey" "$passphrase" "$out"

            fi
        fi
    )
}

function CygbuildCmdPkgSourceStandard()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dummy="srcinstdir $srcinstdir"
    local sigext="$CYGBUILD_GPG_SIGN_EXT"
    local signkey="$OPTION_SIGN"
    local passphrase="$OPTION_PASSPHRASE"

    CygbuildExitIfNoDir "$srcinstdir" \
        "$id: [FATAL] No directory $srcinstdir. Try running [mkdirs]"

    if ! CygbuildDefineGlobalSrcOrig ; then
        CygbuildDie "$id: [FATAL] Source archive location unknown. See -f"
    fi

    dummy="$id BUILD_SCRIPT=$BUILD_SCRIPT"      #  For debug only

    CygbuildExitIfNoFile "$BUILD_SCRIPT" \
        "$id: [ERROR] Can't locate build script [$BUILD_SCRIPT]"

    local orig="$SRC_ORIG_PKG"
    local makepatch="yes"

    if [ ! -f "$orig" ]; then
        CygbuildWarn "$id: [WARN] Cannot diff. Don't know where original "   \
             "source package is. Do you need -f or make a symbolic " \
             "link to PKG-VER.tar.gz?"
        makepatch=
    fi

    CygbuildPackageSourceDirClean

    if [ "$makepatch" ]; then

        CygbuildCmdMkpatchMain      \
            "$OPTION_SIGN"          \
            "$OPTION_PASSPHRASE"    || return $?

        CygbuildPatchCheck          || return $?
    fi

    # .......................................... make source package ...

    local name="$SCRIPT_SRC_PKG_BUILD"    # script-VERSION-RELEASE.sh
    local tarz=$(CygbuildCompressTarOpt)
    local taropt="$verbose $tarz --create --file"

    CygbuildEcho "== Making package [source]" ${FILE_SRC_PKG#$srcdir/}

    local script="$srcinstdir/$name"

    cp --force "$orig" "$srcinstdir/$SRC_ORIG_PKG_NAME" || return $?
    cp "$BUILD_SCRIPT" "$script"                        || return $?

    [ "$$signkey" ] && CygbuildGPGsignFiles "$signkey" "$passphrase" "$script"

    CygbuildFileCleanNow "" $FILE_SRC_PKG $FILE_SRC_PKG$sigext

    local status=0

    CygbuildPushd

        cd "$srcinstdir" || exit $?

        #   Sometimes the directory contains previous releases, like
        #   *-1.tar.*, *-2.tar.*  when the current release source
        #   is -3.

        local pkg="$PKG-$VER-$REL"
        local re

        CygbuildStrToRegexpSafe "$pkg" > $retval
        [ -s $retval ] && re=$(< $retval)

        ls *$PKG-$VER*-* 2> /dev/null |
            $EGREP --invert-match "$re" > $retval

        if [ -s $retval ]; then
            CygbuildWarn "-- [NOTE] Deleting old releases from" \
                         ${srcinstdir#$srcdir/}

            rm $verbose $(< $retval) || exit $?
        fi

        #   Do not include binary package. Neither *src packages.

        local pkg="$FILE_SRC_PKG"

        tar $taropt $FILE_SRC_PKG \
             $(ls $PKG*  | $EGREP -v "$pkg|-src\.tar|$VER-[0-9]+\.tar")

        status=$?

    CygbuildPopd

    if [ "$status" = "0" ]; then
        CygbuildGPGsignFileNow $FILE_SRC_PKG
    fi

    return $status
}

function CygbuildCmdPkgSourceExternal ()
{
    local id="$0.$FUNCNAME"
    local prg="$scriptPackagesSource"
    local status=0

    CygbuildPushd
        cd "$instdir" || exit 1

        eCygbuildEcho "== [NOTE] Making package [source] with external:" \
             ${prg#$srcdir/} $PKG $VER $REL

        CygbuildChmodExec $prg

        $prg $PKG $VER $REL $TOPDIR ||
        {
            status=$?
            CygbuildWarn "$id: [ERROR] Failed create source package."
        }

    CygbuildPopd

    return $status
}

#######################################################################
#
#       Making packages from CVS
#
#######################################################################

function CygbuildCmdPkgSourceMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dummy="pwd $(pwd)"                # For debug only

    local type
    CygbuildVersionControlType > $retval
    [ -s $retval ] && type=$(< $retval)

    [ "$type" ] &&
        CygbuildVerb "-- [INFO] Source is version controled with $type"

    if [ -f "$SCRIPT_SOURCE_PACKAGE" ]; then
        CygbuildCmdPkgSourceExternal
    fi

    CygbuildCmdPkgSourceStandard
}

function CygbuildCmdDownloadUpstream ()
{
    local id="$0.$FUNCNAME"
    local PRG="pwget"
    local bin=$(CygbuildWhich $PRG)

    CygbuildEcho "-- Upstream download: checking for new versions..."

    if [ ! "$bin" ]; then
        CygbuildWarn "-- [ERROR] '$PRG' not found in PATH."
        CygbuildWarn "-- Download from" \
            "http://freecode.net/projects/perl-webget"
        return 1
    fi

    local confdir=${DIR_CYGPATCH:-CYGWIN-PATCHES}
    local name="upstream.perl-webget"
    local conf=$(cd "$confdir" && ls "$(pwd)"/$name)

    if [ ! -f "$conf" ]; then
        CygbuildDie "-- [ERROR] $conf/ subdirectory not found." \
            "Cannot read download instructions."
    fi

    local pkg=$(awk '/tag[0-9]:/  {print $2; exit}' $conf)

    if [ ! "$pkg" ]; then
        CygbuildDie "-- [ERROR] Can't parse 'tag' from $conf"
    fi

    (
        [[ "$*" == *@(--debug|-d\ )* ]] && OPTION_DEBUG=debug

        [ "$OPTION_DEBUG" ] && set -x

        cd .. &&
        perl $bin ${OPTION_DEBUG:+--debug=3} --verbose \
             --new --config $conf --tag $pkg
    )
}

#######################################################################
#
#       Makefile functions
#
#######################################################################

function CygbuildPostinstallWriteStanza()
{
    local type="$1"
    local str="$2"
    local file="$SCRIPT_POSTINSTALL_CYGFILE"
    local stanza="#:$type"

    if CygbuildGrepCheck "^[# ]*$stanza" "$file" ; then
         CygbuildVerb "-- Skip, existing stanza found: $type"
        return 0
    fi

    echo -e "$stanza\n$str" >> "$file" || return 1
}

function CygbuildPostinstallWriteMain()
{
    local id="$0.$FUNCNAME"
    local type="$1"
    local str="$2"
    local file="$SCRIPT_POSTINSTALL_CYGFILE"

    if ! CygbuildIsTemplateFilesInstalled ; then
        CygbuildWarn "$id: [ERROR] No $CYGBUILD_DIR_CYGPATCH_RELATIVE/ " \
             "Please run command [files] first"
        return 1
    fi

    if [ ! "$type" ]; then
        CygbuildWarn "$id: [FATAL] input arg TYPE is empty"
        return 1
    fi

    if [ ! "$str" ]; then
        CygbuildWarn "$id: [FATAL] input arg STR is empty"
        return 1
    fi

    CygbuildVerb "-- Postinstall setup: $type"

    if [ ! -f "$file" ]; then
        echo "\
#!/bin/sh
# This file has been automatically generated by $CYGBUILD_NAME
#
# Please do not remove section comments '#:<name>'

set -e

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LC_ALL=C

dest=\$1

"       >  $file || return 1
    fi

    CygbuildPostinstallWriteStanza "$type" "$str"
    local stat=$?

    CygbuildChmodExec "$file"
    return $stat
}

function CygbuildPreRemoveWrite()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$SCRIPT_PREREMOVE_CYGFILE"
    local dest="$DIR_DEFAULTS_GENERAL"

    if ! CygbuildIsTemplateFilesInstalled ; then
        CygbuildWarn "$id: ERROR No $CYGBUILD_DIR_CYGPATCH_RELATIVE/ " \
             "Please run command [files] first"
        return 1
    fi

    CygbuildEcho "-- Writing /etc preremove script"

    # if [ -f "$file" ]; then
    #   CygbuildWarn "-- [WARN] Already exists. Won't overwrite" \
    #       ${file#$srcdir/}
    #   return 0
    # fi

    find "$dest" \
        ! -path $dest \
        -a ! -name preremove \
        -a ! -name postinstall \
        > $retval

    [ -s $retval ] || return 0

    local item list

    while read item
    do
        [ -d "$item" ] && continue

        item=${item#$dest/}

        list="$list $item"
    done < $retval

    [ "$list" ] || return 0

    echo "\
#!/bin/sh
# This file has been automatically generated by $CYGBUILD_NAME
# This script removes configuration files. New ones
# are installed afterwards by postinstall script.

set -e

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LC_ALL=C
dest=\$1  # Only used for testing

echo \"\$0: Removing unmodified configuration files.\"

fromdir=/etc/defaults
for file in $list
do
    prev=\"\$fromdir/\$file.prev\"
    current=\"\$fromdir/\$file\"
    to=\"\$dest/\$file\"

    if [ ! -e \"\$prev\" ]; then        # First installation
        rm -vf \"\$to\"
        cp -vf \"\$current\" \"\$prev\"
        continue
    fi

    if [ -e \"\$to\" ]; then            # Next installations
        if cmp --quiet \"\$prev\" \"\$to\" ; then
            echo \"\$0: \$to hasn't been modified, will update\"
            rm -vf \"\$to\"
        fi
    fi

    cp -vf \"\$current\" \"\$prev\"

done

# End of file
" > $file

    local stat=$?

    CygbuildChmodExec "$file"
    return $stat
}

function CygbuildMakefileCheck()
{
    local id="$0.$FUNCNAME"

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName > $retval || exit 1
    local file=$(< $retval)

    if [ "$file" ]; then

        $EGREP --line-number --regexp='^[^#]+-lc\b' $file /dev/null > $retval

        if [ -s $retval ]; then
            CygbuildWarn "-- [WARN] Linux -lc found. Make it read -lcygwin"
            cat $retval

            #   With autoconf files, editing Makefile does no good.
            #   because next round of [conf] will wipe it. The changes
            #   must be done elsewhere

            if [ -f "$file.in" ]; then
                CygbuildEcho "-- [NOTE] Change *.in files to link against -lcygwin"
            fi
        fi
    fi
}

function CygbuildPerlPodModule()
{
    #  =head2 Mon Dec  1 16:22:48 2003: C<Module> L<libwww-perl|libwww-perl>
    #  =head2 Fri Jan 30 19:39:27 2004: C<Module> L<Locale::gettext|Locale::gettext>

    #   Return "libwww-perl"

    local id="$0.$FUNCNAME"
    local file="$1"

    if [ "$file" ]; then
        awk -F"<" '
        {
            module=$3;
            gsub("[|].*", "", module);
            print module;
            exit
        }' $file /dev/null
    fi
}

# 2012-10-04 No longer used. Concensus is that perllocal.pod is not
# used in Cygwin

function CygbuildMakeRunInstallFixPerlPostinstall()
{
    # Handle perllocal.pod

    local id="$0.$FUNCNAME"
    local module="$1"

    if [ ! "$module" ]; then
        return 1
    fi

    #  There is one problem. make install wants to append to file:
    #  /usr/lib/perl5/5.8.0/cygwin-multi-64int/perllocal.pod
    #
    #  installed as:
    #  .inst/usr/lib/perl5/5.8.0/cygwin-multi-64int/perllocal.pod
    #
    #  and upon unpack it would replace the existing file. Tackle that.

    find "$instdir" -name perllocal.pod > $retval

    if [ ! -s $retval ]; then
        CygbuildVerb "-- [NOTE] perllocal.pod not foundxs"
        return 0
    fi

    local poddir="/usr/share/perl/cygwin-pods"
    local storedir="$instdir$poddir"
    local file

    #  install in /usr/share/perl/cygwin-pods/<packagename>.pod and
    #  cat the contents to /usr/lib/perl5/5.8/cygwin/perllocal.pod
    #  in postinstall

    while read file
    do
        CygbuildPerlPodModule $file > $retval
        local modulename=$(< $retval)

        if [ ! "$modulename" ]; then
            CygbuildWarn "-- [WARN] Couldn't find Perl module name $file"
            return 1
        fi

        local dir=${file%/*}
        local name=${file##*/}
        local realdir=${dir#*$instdir_relative}    # relative .inst/usr => absolute /usr

        local from="$poddir/$PKG.pod"
        local to="$realdir/$name"

        install -D -m 644 "$file" "$storedir/$PKG.pod" || return $?

        rm "$file" || return $?

        CygbuildEcho "-- Perl install fix: $from"

        #   /usr/share/perl/cygwin-pods/linklint.pod
        #   ...
        #   C<EXE_FILES: linklint-2.3.5>

        local commands="\
from='$from'
to='$to'
grep -Eq 'EXE_FILES:[[:space:]]+$PKG' \$to || cat \"\$from\" >> \"\$to\"\
"

        CygbuildPostinstallWriteMain "Perl" "$commands" || return $?

    done < $retval

# FIXME: remove
    #   Remove perl directory if there are no files in it

#     local libdir="$instdir/usr/lib"

#     file=

#     while read file
#     do
#       break
#     done <  <(find "$libdir/perl5" -type f)

#     if [  "$file" ]; then
#       rm -rf "$libdir/perl5"
#       CygbuildIsDirEmpty "$libdir" && rmdir "$libdir"
#    fi

}

function CygbuildPod2man()
{
    local file=$1
    local mansect=$2
    local Destdir=$3

    local dir="."                                       # Not used now

    if [[ "$file" == */* ]]; then
        dir=${file%/*}
    fi

    local package=${file##*/}
    local package=${package%.*}

    if [ "$mansect" = "" ]; then
        mansect="1"

        #  program.1

        if [[ $package == *.[0-9] ]]; then
            mansect=${package##*.}
            package=${package%.$mansect}
        fi
    fi

    local date=$(date "+%Y-%m-%d")
    local podcenter=$date

    local mandir="$instdir/usr/share/man"
    local destdir="${Destdir:-$mandir/man$mansect}"
    local manpage="$destdir/$package.$mansect"

    mkdir --parents $destdir

    # --official --release 0.4

    pod2man --center="$podcenter" \
            --name="$package" \
            --section="$mansect" \
            --release="$date" \
            $file \
    | sed "s,[Pp]erl v[0-9.]\+,$package," > $manpage &&
    rm --force pod*.tmp
}

function CygbuildMakeRunInstallFixPerlManpage()
{
    local id="$0.$FUNCNAME"
    local bindir="$instdir/usr/bin"

    [ -d "$bindir" ] || return 0

    #  See if we can use POD section to generate manuals

    local mandir="$instdir/usr/share/man"
    local destdir="$mandir/man1"
    local file name manpage _file

    for file in $bindir/*
    do
        _file=${file#$srcdir/}
        name=${file##*/}
        name=${name%.pl}
        manpage="$destdir/$name.1"

        if [ ! -f "$manpage" ]; then
            if $EGREP --quiet "^=cut" $file ; then
                CygbuildEcho "-- [NOTE] Making POD manpage from $_file"
                CygbuildPod2man "$file"
            else
                :
                # FIXME: Is this check correct?
                # CygbuildVerb "-- [NOTE] possibly no manpage for $_file"
            fi
        fi
    done
}

function CygbuildMakeRunInstallFixPerlMain()
{
    local id="$0.$FUNCNAME"

    local retval=$CYGBUILD_RETVAL.$FUNCNAM
    local module="$CYGBUILD_STATIC_PERL_MODULE"

    [ "$module" ] || return 0

    # No longer used
    # CygbuildMakeRunInstallFixPerlPostinstall "$module"
}

function CygbuildMakefilePrefixCheck()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local makefile="$1"

    if [ ! "$makefile" ] || [ ! -f "$makefile" ] ; then
        return 0
    fi

    CygbuildIsDestdirSupported
    local destdir=$?

    if [ ! "$destdir" = "0" ]; then

        #   In some very weird cases, File::Find.pm dies with
        #   symbolic links, so we might end here saying "no destdir".
        #   Double check the situation with grep. Do we see line like:
        #
        #    $(INSTALL) -d $(DESTDIR)$(exec_prefix)/bin

        local list

        [ -f src/Makefile    ] && list="$list src/Makefile"
        [ -f source/Makefile ] && list="$list source/Makefile"

        local opt

        [ ! "$verbose" ] && opt="-q"

        if $EGREP $opt \
           "^[[:space:]]*DESTDIR|^[^[:space:]]+=.*DESTDIR|^[^#].*[$][({]DESTDIR" \
           $makefile $list 2> /dev/null
        then
            destdir=0
        fi
    fi

    #   There is no DESTDIR support, so try to see if Makefile uses
    #   'prefix' then

    if [ ! "$destdir" = "0" ]; then

        #   "prefix ?= /usr/local"

        local pre='^[[:space:]]*prefix[[:space:]]*[+?]?='
        local Pre='^[[:space:]]*PREFIX[[:space:]]*[+?]?='

        #   Some packages have directories: Makefile.inc/
        #   Because this is builddir, all files are symlinks, so "ls -F"
        #   reports "Makefile@". Ignore patch reject files.

        ls -F | awk '
            ! /\.(orig|rej)/ && /(\.mk|[Mm]akefile).*@/ {
                sub("@","");
                print
            }' > $retval

        CygbuildEcho "-- Makefile may not use DESTDIR"

        if [ -s $retval ]; then

            if $EGREP "$pre" $(< $retval) 2> /dev/null ; then
                OPTION_PREFIX_MODE="automatic-prefix"
                return 0
            fi

            if $EGREP "$Pre" $(< $retval) 2> /dev/null ; then
                OPTION_PREFIX_MODE="automatic-PREFIX"
                return 0
            fi
        fi

        if MakefileUsesRedirect $makefile ; then
            CygbuildEcho "-- Hm, Makefile seems to use redirect option -C"
            return 0
        fi

        local file="$DIR_CYGPATCH/install.sh"
        local msg

        if [ ! -f $file ]; then
            msg=". You may need to patch makefile or write install.sh"
        fi

        CygbuildWarn \
            "-- [WARN] Makefile may not use variables 'DESTDIR'" \
            "or prefix/PREFIX$msg"
    fi
}

function CygbuildPythonCompileFiles()
{
    local id="$0.$FUNCNAME"

    #   prgcwd = os.path.split(sys.argv[0])[0]
    #
    #   http://www.python.org/doc/current/lib/module-os.html
    #   http://www.python.org/doc/current/lib/module-os.path.html
    #
    #   NOTE: Python needs indentation to start to the LEFT.
    #
    #   sys.platform  will return: win32, cygwin, darwin, linux
    #   and os.name will indicate 'posix' as needed.

    python -c '
import os, sys, py_compile
verbose = sys.argv[1]

for arg in sys.argv[2:]:
        file = os.path.basename(arg)
        dir  = os.path.dirname(arg)
        if os.path.exists(dir):
            os.chdir(dir)
            if verbose:
                print "-- Python compile %s" % (file)
            py_compile.compile(file)
    ' "${verbose:+1}" "$@"
}

function CygbuildPythonCompileDir()
{
    local id="$0.$FUNCNAME"
    local dir="$1"

    #   See "Compiling Python Code" by Fredrik Lundh
    #   http://effbot.org/zone/python-compile.htm

    python -c '
import os, sys, compileall
dir = sys.argv[1]
compileall.compile_dir(dir, force=1)
    ' "$dir"
}

function CygbuildMakefileRunInstallPythonFix()
{
    local id="$0.CygbuildMakefileRunInstallPythonFix"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local root="$instdir$CYGBUILD_PREFIX"
    local dir dest

    if [ -d $root/bin/lib/python* ]; then
        #  .inst/usr/bin/lib/python2.4/site-packages/foo/...

        mv $verbose "$root/bin/lib" "$root/" ||
            CygbuildDie "$id: mv error"

        # [ -d "$root/bin" ] && rmdir "$root/bin"
    fi

    #   Move /usr/share/bin to /usr/bin
    #   Move /usr/share/lib to /usr/lib

    for dir in $root/share/bin \
               $root/share/lib
    do
        dest=$dir/../..

        if [ -d "$dir" ]; then
            mv $verbose "$dir/" "$dest/" ||
               CygbuildDie "$id: mv error"
        fi
    done

    #   For some reason the manual pages may be at .inst/man1

    local mandir="$CYGBUILD_PREFIX/$prefix_man"

    for dir in $instdir/{man1,man3,man5,man8}
    do
        [ -d $dir ] || continue

        $INSTALL_SCRIPT $INSTALL_BIN_MODES -d $instdir

        mv $verbose "$dir" "$dest" ||
            CygbuildDie "$id: mv error"
    done

    #   For some reason compiled python objects from
    #   setup.py include FULL PATH where the modules were compiled.
    #   => this is not good, because they are later installed to the
    #   /usr/share/lib/python2.4/site-packages/
    #
    #   You can see the effect by running "strings *.pyc"
    #   => recompile all

    local list rmlist

    find $instdir -type f -name "*.pyc" > $retval
    rmlist=$(< $retval)

    if [ "$rmlist" ]; then
        list=$(echo "$rmlist" | sed 's/\.pyc/.py/g' )
        rm $rmlist
        CygbuildEcho "-- Compiling python files (may take a while...)"
        CygbuildPythonCompileFiles $list
    fi
}

function CygbuildShellEnvironenment()
{
    local list

    [ "$CYGBUILD_CC" ] &&
    list="$list CC='${CYGBUILD_CC}'"

    [ "$CYGBUILD_CXX" ] &&
    list="$list CXX='${CYGBUILD_CXX}'"

    [ "$CYGBUILD_LDFLAGS" ] &&
    list="$list LDFLAGS='${CYGBUILD_LDFLAGS}'"

    [ "$CYGBUILD_CFLAGS" ] &&
    list="$list CFLAGS='${CYGBUILD_CFLAGS}'"

    [ "$CYGBUILD_CXXFLAGS" ] &&
    list="$list CXXFLAGS='${CYGBUILD_CXXFLAGS}'"

    list="$list DESTDIR=$instdir prefix=/usr"

    if CygbuildIsEmpty "$list" ; then
        return 1
    fi

    echo $list
}

function CygbuildRunShell()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local env
    CygbuildShellEnvironenment > $retval
    [ -s $retval ] && env=$(< $retval)

    CygbuildVerb "-- Running $(eval $env) $@"

    eval ${test:+echo} $env "$@"
}

function CygbuildRunRubySetupCmd()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    CygbuildVerb "-- Running Ruby command: $*"

    CygbuildRunShell ruby setup.rb "$@" > $retval 2>&1
    local status=$?

    if [ "$verbose" ] || [ ! "$status" = "0" ] ; then
        cat $retval
    fi

    return $status
}

function CygbuildMakefileRunInstallRubyMain()
{
    local root="$instdir"

    local pfx=${1:-$root}
    [ "$1" ] && shift

    CygbuildRunRubySetupCmd \
        install             \
        --prefix=$pfx
}

function CygbuildRunPythonSetupCmd()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local pybin="$PYTHONBIN"

    CygbuildVerb "-- Running Python command: $*"

    if [ ! -x "$pybin" ]; then
        CygbuildWarn "-- [WARN] Not found $pybin"
        return 1
    fi

    CygbuildRunShell \
        $pybin \
        setup.py \
        "$@" > $retval 2>&1

    local status=$?

    if [ "$verbose" ] || [ ! "$status" = "0" ] ; then
        cat $retval
    fi

    return $status
}

function CygbuildMakefileRunInstallPythonDistutilsStart()
{
    # http://peak.telecommunity.com/DevCenter/EasyInstall#traditional-pythonpath-based-installation

    local conf="$HOME/.pydistutils.cfg"
    local flag="$conf.cygbuild"

    if [ ! -f "$flag" ]; then
        CygbuildRun touch "$conf.cygbuild"

        [ -f "$conf" ] && CygbuildRun cp "$conf" "$conf.bak"

        [ "$test" ] && return 0

        local python=python$PYTHON_VERSION_MAJOR
        local lib=$instdir/usr/lib/$python/site-packages

        echo "\
[install]
install_lib = $lib
install_scripts = $instdir/usr/bin
" > $conf

    fi
}

function CygbuildMakefileRunInstallPythonDistutilsStop()
{
    local conf="$HOME/.pydistutils.cfg"
    local flag="$conf.cygbuild"

    if [ -f "$flag" ]; then
        if [ -f "$conf.bak" ]; then
            CygbuildRun mv "$conf.bak" "$conf"
        else
            CygbuildRun rm "$conf"
        fi

        CygbuildRun rm -f "$flag"
    fi
}

function CygbuildMakefileRunInstallPythonMain()
{
    local root="$instdir$CYGBUILD_PREFIX"

    local pfx=${1:-$root}
    [ "$1" ] && shift

    local docpfx=${1:-$root/share/doc}
    [ "$1" ] && shift

    #   See "2 Standard Build and Install" and section 3, 4
    #   http://docs.python.org/inst/standard-install.html

    #   IT is not possible to define "home" AND prefix variables.
    #   This does not work: --home=$instdir
    #
    #   There is bug in Python: It always install under --prefix,
    #   no matter where --exec-prefix is set to.

    CygbuildMakefileRunInstallPythonDistutilsStart

    local status

    # Some libraries require special setup.py handling
    # in order to install outside of system wide directory:
    #
    # - Custom ~/.pydistutils.cfg
    # - PYTHONPATH set

    local python=python$PYTHON_VERSION_MAJOR
    local lib=$instdir/usr/lib/$python/site-packages

    CygbuildEcho "-- Python $PYTHON_VERSION"

    if CygbuildIsPythonSetuptools ; then
        CygbuildWarn "-- [NOTE] autodetected setuptools"
        CygbuildRun install -d -m 755 $lib
    fi

    (
        export PYTHONPATH="$lib:$PYTHONPATH"

        CygbuildRunPythonSetupCmd       \
            install                    \
            --prefix=$pfx              \
            --exec-prefix=$pfx/bin     \
            ${1:-"$@"}
    )

    status=$?

    CygbuildMakefileRunInstallPythonDistutilsStop

    return $status

}

function CygbuildMakefileRunPythonInDir ()
{
    local dir="$1"
    shift

    [ ! "$dir" ] && CygbuildDie "$id: Missing ARG"

    CygbuildPushd
        cd "$dir" || exit 1
        CygbuildRunPythonSetupCmd "$@"
    CygbuildPopd
}

CygbuildMakefileRunPythonClean ()
{
    CygbuildMakefileRunPythonInDir "$builddir" clean
}

function CygbuildMakefilePrefixIsStandard ()
{
    local id="$0.$FUNCNAME"
    local opt up lower
    local files=$(ls "$@" *.mk 2> /dev/null)

    [ "$verbose" ] || opt="-q"
    [ "$files"   ] || return 0

    if $EGREP $opt "^[[:space:]]*PREFIX[[:space:]]*[+?]?=" $files
    then
        up="PREFIX"
    fi

    if $EGREP $opt "^[[:space:]]*prefix[[:space:]]*[+?]?=" $files
    then
        lower="prefix"
    fi

    if [ ! "$lower" ]; then
        if [ "$up" ]; then
            CygbuildVerb "-- [NOTE] No prefix= but PREFIX= found."
            return 1
        else
            CygbuildWarn "-- [WARN] Makefile prefix= not found."
        fi
    fi
}

function CygbuildMakefileRunInstallCygwinOptions()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local pfx=${1:-"prefix=$CYGBUILD_PREFIX"}
    local docpfx=${2:-$CYGBUILD_DOCDIR_FULL}
    local rest=$3

    local makeEnv="$EXTRA_ENV_OPTIONS_INSTALL"
    local test=${test:+"-n"}

    if [ $test ]; then
        CygbuildEcho "-- [INFO] make(1) called with -n" \
                     "(test mode, no real install)"
    fi

    local makefile
    CygbuildMakefileName > $retval
    [ -s $retval ] && makefile=$(< $retval)

    CygbuildExitIfEmpty "$makefile" \
        "$id: [FATAL] Disk full? File is empty: $makefile"

    if [ "$CYGBUILD_MAKEFLAGS" ]; then
        CygbuildEcho "-- Extra make flags: $CYGBUILD_MAKEFLAGS"
    fi

    #   Use subshell. This way 'source' command won't affect
    #   current environment.

    (
        if [ -f "$makeEnv" ]; then
            CygbuildEcho "--- Reading external env: $makeEnv" \
                 " $makeEnv $instdir $CYGBUILD_PREFIX $exec_prefix"
            source $makeEnv || exit $?
        fi

        local docdir="$DIR_DOC_GENERAL"

        #   Run install with Cygwin options

        [ "$verbose" ] && set -x

        make -f $makefile $test         \
             DESTDIR="$instdir"         \
             DOCDIR="$docdir"           \
             $pfx                       \
             exec_prefix="${pfx#*=}"    \
             man_prefix="$docpfx"       \
             info_prefix="$docpfx"      \
             bin_prefix=                \
             $rest                      \
             $CYGBUILD_MAKEFLAGS        \
             install
    )
}

function CygbuildMakefileRunInstallFixInfo()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   If there are info files, the 'dir' must be removed, otherwise
    #   it would overwrite the central DIR when unpackad.
    #
    #       .inst/usr/share/info/package.info
    #       .inst/usr/share/info/dir

    if ! find $instdir -name dir > $retval; then
        return
    fi

    local file

    while read file
    do
        local name=$DIR_CYGPATCH/postinstall.sh

        if [ ! -f "$name" ]; then
            CygbuildWarn "-- [WARN] removing $file, so you need $name"
        fi

        rm $file
    done < $retval
}

function CygbuildMakefileRunInstallFixMain()
{
    local id="$0.$FUNCNAME"
    CygbuildMakefileRunInstallFixInfo
}

function CygbuildMakefileRunInstallMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local makeScript="$SCRIPT_INSTALL_MAKE_CYGFILE"
    local status=0

    CygbuildMakefileName > $retval
    local makefile=$(< $retval)

    #   install under .inst/

    CygbuildEcho "-- Running 'make install' (or equiv.) in" \
                 ${builddir#$srcdir/}

    if [ -f "$makeScript" ]; then

        CygbuildEcho "--- Running external make:" ${makeScript#$srcdir/} \
             ${instdir#$srcdir/}        \
             $CYGBUILD_PREFIX           \
             ${exec_prefix#$srcdir/}

        echo "$id: NOT YET IMPLEMENTED"

        #todo: FIXME unfinished idea.
        exit 1

        CygbuildPushd
            cd "$builddir" || exit 1
            $makeScript "$instdir" "$CYGBUILD_PREFIX" "$exec_prefix"
            status=$?
        CygbuildPopd

        return $status

    elif CygbuildIsPythonPackage ; then

        CygbuildVerb "-- ... Looks like Python package [install]"

        CygbuildPushd
            cd "$builddir" || exit 1
            CygbuildMakefileRunInstallPythonMain &&
            CygbuildMakefileRunInstallPythonFix
            status=$?
        CygbuildPopd

        return $status

    elif CygbuildIsRubyPackage ; then

        CygbuildVerb "-- ... Looks like Ruby package [install]"

        CygbuildPushd
            cd "$builddir" || exit 1
            CygbuildMakefileRunInstallRubyMain
            status=$?

        CygbuildPopd

        return $status

    elif CygbuildIsPerlPackage ; then

        # Perl creates Makefile from Makefile.PL
        #
        # Most Perl program don't use $DESTDIR unless they are hand
        # crafter. Plain MakeMaker only uses PREFIX.

        local pfx="$instdir$CYGBUILD_PREFIX"
        local PFX="PREFIX=$pfx"

        if CygbuildIsDestdirSupported ; then
            PFX="$CYGBUILD_PREFIX"
        fi

        CygbuildVerb "-- ... Looks like Perl package"

        CygbuildPushd
            cd "$builddir" || exit 1
            CygbuildMakefileRunInstallCygwinOptions "$PFX" &&
            CygbuildMakeRunInstallFixPerlMain       &&
            CygbuildInstallCygwinPartPostinstall
            status=$?
        CygbuildPopd

        return $status

    elif [ "$makefile" ] && [ -f "$makefile" ]; then

        #   DESTDIR is standard GNU ./configure macro,
        #   which points to root of install.
        #   prefix and exec_prefix are relative to it.
        #
        #   Debian package uses @bin_prefix@ to install
        #   programs under another name. Do not set it

        local pfx="$CYGBUILD_PREFIX"

        if CygbuildIsAutotoolPackage ; then
            CygbuildVerb "-- ...Looks like standard autotool package"
        fi

        CygbuildMakefilePrefixCheck "$makefile"

        local pvar="prefix"

        if [[ "$OPTION_PREFIX_MODE" == *automatic-* ]]; then
            pvar=${OPTION_PREFIX_MODE#*-}  # automatic-PREFIX => PREFIX

            #  Packages that do not use DESTDIR
            pfx="$instdir$CYGBUILD_PREFIX"

        elif [ "$OPTION_PREFIX_MODE" ]; then        # User option
            pfx="$instdir$OPTION_PREFIX_MODE"
        fi

        CygbuildConfigureOptionsExtra > $retval
        local extra=$(< $retval)

        #  GNU autoconf uses 'prefix'

        local docprefix="/$CYGBUILD_DOCDIR_PREFIX_RELATIVE"
        pfx=${pfx%/}                                # remove trailing slash

        local PFX="$pvar=$pfx"

        if ! CygbuildMakefilePrefixIsStandard "$makefile"; then
            CygbuildVerb "-- Using PREFIX variable"
            PFX="PREFIX=$pfx"
        fi

        CygbuildPushd
            cd "$builddir" || exit 1
            CygbuildMakefileRunInstallCygwinOptions "$PFX" "$docprefix"
            status=$?
        CygbuildPopd

        return $status

    else

        CygbuildNoticeBuilddirMaybe

        CygbuildWarn "-- [WARN] There is no Makefile." \
             "Did you forget to run [configure] or repeat [shadow]?"

    fi
}

#######################################################################
#
#       Build functions
#
#######################################################################

function CygbuildCmdMkdirs()
{
    local id="$0.$FUNCNAME"
    local verbose="$1"

    CygbuildVerb "-- Making Cygwin directories under $srcdir"
    local status=0
    local dir

    CygbuildPushd

        cd "$srcdir" || exit 1

        for dir in $builddir $instdir $srcinstdir $DIR_CYGPATCH
        do
            if [ -d "$dir" ]; then
                CygbuildVerb "-- Skipped; already exists $dir"
                continue
            fi

            if ! CygbuildRun mkdir $verbose -p "$dir" ; then
                status=$?
                break
            fi
        done

    CygbuildPopd

    return $status
}

function CygbuildExtractTar()
{
    local id="$0.$FUNCNAME"
    local file=$SRC_ORIG_PKG
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   Check that CygbuildDefineGlobalSrcOrig
    #   defined variables correctly

    if ! CygbuildDefineGlobalSrcOrig ; then
        echo "$id: [ERROR] Original source kit location not known, see -f."
        return 1
    fi

    local file=$SRC_ORIG_PKG

    if [ ! -f "$file" ]; then
        CygbuildWarn "$id: [FATAL] $file not found. Check" \
             "function CygbuildDefineGlobalMain()"
        return 1
    fi

    CygbuildStrPackage $file > $retval
    local package=$(< $retval)

    CygbuildStrVersion $file > $retval
    local ver=$(< $retval)

    if [ ! "$package" ] || [ ! "$ver" ]; then
        CygbuildWarn "$id: [FATAL] $file does not look like package-N.N.tar.* "
        return 1
    fi

    local expectdir="$package-$ver"

    CygbuildTarOptionCompress $file > $retval
    local z=$(< $retval)

    #   Look inside archive to see what directry it contains.
    #   WE need this in case original source does not have
    #   structure at all or has weird directory.

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildTarDirectory $file > $retval || return $?
    local dir=$(< $retval)

    local opt="$verbose --no-same-owner --no-same-permissions --extract $z --file"
    CygbuildEcho "-- Extracting $file"

    if [ "$dir" != "$expectdir" ]; then
        CygbuildEcho "-- [WARN] archive does not contain $expectdir/"
    fi

    if [[ "$dir" != *[a-zA-Z]* ]]; then

        CygbuildEcho "-- Hm,  archive does not have good subdirectory, so" \
             "creating dir $expectdir and unpacking there"
        mkdir "$expectdir" || return $?

        local status=0

        tar --directory "$expectdir" $opt "$file"  ||
        {
            status=$?
            CygbuildPopd
            return $status
        }

    else
        if [ -d "$dir" ] ; then
            CygbuildDie \
                "-- [ERROR] Cannot unpack, existing directory found: $dir"
        fi

        tar $opt "$file" || return $?

        if [ "$dir" != "$expectdir" ]; then

            #   Sometimes package name only varies in case, which is not good
            #       LibVNCServer-0.6  <=> libvncserver-0.6
            #   Windows cannot rename such directory because it would be the
            #   same.

            echo $dir | tr 'A-Z' 'a-z' > $retval
            local name1=$(< $retval)

            echo $$expectdir | tr 'A-Z' 'a-z' > $retval
            local name2=$(< $retval)

            if [ "$name2" = "$name1" ]; then
                CygbuildEcho "-- Unpack dir $dir is same $name2 - Skipped"
            else
                CygbuildEcho "-- Renaming unpack dir: mv $dir $expectdir"
                mv "$dir" "$expectdir" || return $?
            fi

        fi
    fi
}

function CygbuildExtractWithScript()
{
    local id="$0.$FUNCNAME"
    local prg="$1"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if [ ! "$srcdir" ]; then
        echo "$id: [FATAL] 'srcdir' not defined"
        return 1
    fi

    CygbuildEcho "--- Getting external sources with: $file"

    #   Now run the script and if it succeeds, we are ready to proceed to
    #   patching

    CygbuildChmodExec $prg

    ./$prg  && \
    {
        if [ ! -d "$srcdir" ]; then
            #  The sript did not unpack to package-N.N, fix it

            CygbuildGetOneDir > $retval
            dir=$(< $retval)

            #   Good, there no more than ONE directory, which
            #   was just made by that script.

            to=$(basename $srcdir)

            if [ "$dir" ]; then
                CygbuildEcho "-- [!!] Download done. Symlinking $dir => $to" \
                     "in $(pwd)"

                ln --symbolic "$dir" "$to" ||
                    CygbuildDie "-- [FATAL] symlink failed"

                mkdir --parents "$srcdir" ||
                    CygbuildDie "-- [FATAL] mkdir failed"
            fi
        fi
    }
}

function CygbuildExtractMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    if CygbuildSourceDownloadScript > $retval ; then
        local file=$(< $retval)
        CygbuildExtractWithScript $file
    else
        CygbuildExtractTar
    fi
}

#######################################################################
#
#       Patch functions
#
#######################################################################

function CygbuildPatchListDisplay()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$CYGPATCH_DONE_PATCHES_FILE"

    if [ -s "$file" ]; then
        CygbuildEcho "-- [INFO] Applied local patches"
        sort --unique $file
    fi
}

function CygbuildPatchDiffstat()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$1"

    if [ ! "$file" ]; then
        CygbuildWarn "$id: Missing argument FILE"
        return 1
    fi

    CygbuildWhichCheck diffstat || return 0

    local check="$file"

    #  We're not interested in CYGWIN-PATCHES/
    #  Excldue "diff" commands embedded in patch

    if CygbuildWhichCheck filterdiff ; then
        $EGREP -v "^diff " $file |
        filterdiff -x "*$CYGBUILD_DIR_CYGPATCH_RELATIVE*" > $retval.diff

        check="$retval.diff"
    fi

    if [ -s "$check" ]; then
        CygbuildEcho "-- Patched local changes"
        diffstat "$check"
    fi
}

function CygbuildPatchCheck()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$FILE_SRC_PATCH"

    if [ -f "$file" ]; then

        local _file=${file#$srcdir/}   # Relative path name

        if [ "$verbose" ]; then
            CygbuildEcho "-- content of $_file"
            awk '/^\+\+\+ / {print "   " $2}' $file > $retval

            #  Arrange listing a little. Subdirectories last.
            #    foo-2.5/CYGWIN-PATCHES/foo.README
            #    foo-2.5/CYGWIN-PATCHES/patches/...

            $EGREP "/.+/.+/"    $retval > $retval.dir

            if [ -s "$retval.dir" ]; then
                $GREP --invert-match --fixed-strings \
                    --file=$retval.dir  $retval | sort
                sort $retval.dir
            else
                cat $retval
            fi

        fi

        CygbuildPatchDiffstat "$file"

        #  Seldom anyone makes changes in C-code or headers
        #  files. Let user audit these changes.
        #
        # --- src/lex.yy.c   2000-04-01 18:33:34.000000000 +0000
        # +++ new/lex.yy.c   2004-01-29 18:04:18.000000000 +0000

        local notes
        $EGREP -ie '^(\+\+\+).*\.([ch]|cc|cpp) ' $file > $retval

        [ -s $retval ] && notes=$(< $retval)

        if [ "$notes" ]; then
            CygbuildWarn "-- [WARN] Patch check. Please verify $_file"
            CygbuildEcho "-- [NOTE] I'm just cautious. Perhaps files below"
            CygbuildEcho "-- [NOTE] are auto-generated or modified by you."
            CygbuildWarn "$notes"
            return 0
        fi

        notes=""

        $EGREP --line-number "No newline at end of file" $file > $retval
        [ -s $retval ] && notes=$(< $retval)

        if [ "$notes" ]; then
            CygbuildWarn "-- [WARN] Patch check. Please verify $_file"
            CygbuildWarn "$notes"
            return 0
        fi

        if [[ ! -s $file ]]; then
            CygbuildWarn "-- [ERROR] Patch file is empty $_file"
            return 1
        fi
    else
        CygbuildWarn "-- [ERROR] Patch file is missing $_file"
        return 1
    fi
}

function CygbuildPatchFindGeneratedFiles()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local retval2=$retval.2

    local origdir="$1"
    local dir="$2"
    local optextra="$3"

    CygbuildExitIfNoDir "$origdir" "$id: [ERROR] parameter failure 'origdir' $origdir"
    CygbuildExitIfNoDir "$dir" "$id: [ERROR] parameter failure 'dir' $dir"

    #   Many packages do not 'clean' the files correctly and there may
    #   be left files that were generated by ./configure. Compare
    #   the original file listing against current file listing to
    #   see if some files were not cleaned. These should be ignored while
    #   making a patch
    #
    #   The typical case is a LEX generated files.
    #
    #       lexpgn.l => lexpgn.c

    local exclude

    exclude="$exclude $cygbuild_opt_exclude_tmp_files"
    exclude="$exclude $cygbuild_opt_exclude_bin_files"
    exclude="$exclude $cygbuild_opt_exclude_dir"
    exclude="$exclude $cygbuild_opt_exclude_library_files"
    exclude="$exclude $optextra"

    #  At this point, assume that any .h or .c file is generated
    #  if it is not in the original package.

    diff $exclude --brief --recursive $origdir $dir > $retval
    local status=$?    # For debug, the diff(1) status code

    if [ "$status" = "2" ]; then
        return 1
    fi

    local ret file

    awk '/Only in.*\.[ch]/ {print $4}' $retval > $retval2

    while read file
    do
        CygbuildWarn "-- [NOTE] Excluding from patch" \
             "a Makefile/patch generated file $file"
        ret="$ret --exclude=$file"
    done < $retval2

    #   All file.ext files are generated if they have corresponding
    #   file.ext.in counterpart
    #
    #   Only in /usr/src/build/catdoc/package-N.N/doc: package.1

    local dummy="Forget *.in automake generated files"
    local name try

     awk \
        '
            /Only in.*/ {
                path=$3;
                file=$4;
                gsub(":", "", path);
                print path "/" file;
            }
        ' $retval > $retval2

    while read file
    do

        [ -d "$file" ]          && continue     # Skip made directories
        [[ $file = $origdir* ]] && continue

        name=${file##*$dir/}
        try="$origdir/$name.in"

        if [ -f "$try" ]; then
            CygbuildWarn \
                "-- [NOTE] Excluding from patch a Makefile generated" \
                 "file $name"

            ret="$ret --exclude=${name##*/} --exclude=${name##*/}.in"
        fi

    done < $retval2

    #   All executables are excluded too. Some Linux packages
    #   include pure binary "file", so exclude also "file.exe"
    #   under Cygwin.

    local dummy="Forget executables"

    if ls *.exe > $retval 2> /dev/null ; then
        while read file
        do
            name=${file%.exe}
            ret="$ret --exclude=$file --exclude=$name"
        done < $retval
    fi

    #   Anyway, exclude the package binary name; just in case it
    #   WAS included in original package (bad, possibly a mistake)

    ret="$ret --exclude=$PKG"

    echo $ret
}

#######################################################################
#
#       Other
#
#######################################################################

CygbuildCmdDownloadCygwinPackage ()
{
    local pkg="$1"
    local mode=${2:-"source-binary"}            # Download both
    local rm_cache="$3"
    local arch="$4"

    if [ ! "$arch" ]; then
        arch=$(CygbuildArchId)
    fi

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local url="$CYGBUILD_SRCPKG_URL"
    local wget="$WGET"

    if [ ! "$pkg" ]; then
        CygbuildDie "$id: [FATAL] command needs PACKAGE name"
    elif [[ "$pkg" == -* ]]; then
        CygbuildDie "$id: [FATAL] suspicious package name: $pkg"
    fi

    if [ ! "$wget" ]; then
        CygbuildDie "$id: [FATAL] wget not in PATH"
    fi

    CygbuildEcho "-- Download Cygwin package: $pkg"
    CygbuildVerb "-- Using download location $url"

    url=${url%/}        # Remove trailing slash

    local file="setup.ini"
    local cachedir="$CYGBUILD_CACHE_DIR"
    local cache="$cachedir/$file"

    [ -d "$cachedir" ] ||
        mkdir --parents $verbose "$cachedir"

    if [ "$pkg" ]; then
        CygbuildEcho "-- Using cache $cache (remove to get updated one)"
    else
        CygbuildEcho "-- [ERROR] Missing source PACKAGE name" >&2
        return 1
    fi

    CygbuildFileDaysOld "$cache" > $retval &&

    local days=$(< $retval)
    days=${days%.*}             # remove decimals from N.NNNN days

    if [ "$rm_cache" ]; then
        CygbuildEcho "-- [NOTE] removing cache: $cache"
    elif [ -f "$cache" ] && [ ! -s "$cache" ]; then
        #  If file exists, but is empty, remove it
        rm --force "$cache"
    elif [ "$days" ]  && [[ $days -gt 7 ]]; then
        CygbuildEcho "-- [NOTE] Refreshing $days days old cache file"
        rm --force "$cache"
    fi

    if [ ! -f "$cache" ] || [ ! -s "$cache" ]; then
        CygbuildEcho "-- Wait, downloading Cygwin package information."

	local URL="$url/$arch/$file"
	
	if ! $wget --quiet --output-document=$cache "$URL" ; then
	    CygbuildWarn "[ERROR] Failed to download $URL"
	    CygbuildWarn "[ERROR] Set environment variable CYGBUILD_SRCPKG_URL"
	    return $?
	fi
    fi

    # @ xfig
    # sdesc: "Xfig (main package)"
    # ldesc: "Xfig is a menu-driven tool that allows the user to draw and
    # manipulate objects interactively in an X window.  The resulting
    # pictures can be saved, printed on postscript printers or converted to
    # a variety of other formats (e.g. to allow inclusion in LaTeX
    # documents)."
    # category: X11
    # requires: cygwin xorg-x11-bin zlib jpeg libpng Xaw3d transfig xfig-lib ghostscript-x11 tar
    # version: 3.2.4-6
    # install: release/X11/xfig/xfig-3.2.4-6.tar.bz2 3574763 1c4a8e1ee58b7dfcdad3f8bb408dcd88
    # source: release/X11/xfig/xfig-3.2.4-6-src.tar.bz2 5192668 fc6917de1ade3bceaaa889ee1356bf5c
    # [prev]
    # version: 3.2.4-5
    # install: release/X11/xfig/xfig-3.2.4-5.tar.bz2 3583633 2bbd3da200a524fb9289bfc18cee507b
    # source: release/X11/xfig/xfig-3.2.4-5-src.tar.bz2 5191809 b59f9f7f69899d101c87813479a077c0

    CygbuildEcho "-- Wait, searching package $pkg"

    awk \
    '
        $0 ~ re {
            found = 1;
        }
        found > 0 && /^source:/ {
            print $2;
            exit
        }

    ' re="^[@] +$pkg *\$" $cache > $retval

    if [ ! -s "$retval" ]; then
        CygbuildWarn "-- [ERROR] Need to refresh cache?" \
            "No such package: $pkg"
        return 2
    fi

    local path=$(< $retval)
    local binpath=${path/-src/}

    local dir=${path%/*}
    local archive=${path##*/}
    local name=${archive%.tar*}
    local name=${name%-src*}
    local name=${name%.orig*}

    local list

    [[ "$mode" == *binary* ]] && list="$list $url/$binpath"
    [[ "$mode" == *source* ]] && list="$list $url/$path $url/$dir/setup.hint"

    if [ ! -f "$archive" ]; then
        $wget --no-directories --no-host-directories --timestamping \
            $list ||
        CygbuildDie "-- [ERROR] Download failed."
    fi

    [[ "$mode" == *source* ]] || return 0

    CygbuildEcho "-- Wait, extracting source and preparing *.patch file"

    if [ -f "$archive" ] && { [ -f $name*.sh ] || [ -f $name*.cygport ]; }
    then
        CygbuildEcho "-- Good, archive already extracted: $archive"
    else
        tar $verbose --extract --no-same-owner --no-same-permissions \
            --file="$archive"
    fi

    if ! CygbuildWhichCheck filterdiff ; then
        CygbuildWarn "-- [WARN] Skipped patch explode. filterdiff not in PATH"
        return 0
    fi

    local cygdir=${CYGBUILD_DIR_CYGPATCH_RELATIVE:-"CYGWIN-PATCHES"}

    ls *.patch 2> /dev/null |
        grep --invert-match --regexp='-rest.patch' \
        > $retval

    while read patch
    do
        if [ ! -d "$cygdir" ]; then
            if lsdiff $patch | grep "$cygdir" > /dev/null ; then
                filterdiff -i "*CYGWIN*" $patch | patch -p1 --forward
            fi
        fi

        if lsdiff $patch |
           grep --invert-match "$cygdir" > /dev/null
        then

            local file=${patch%.patch}-rest.patch

            [ ! -f "$file" ] &&
            filterdiff -x "*CYGWIN*" $patch > "$file"

            if cmp "$patch" "$file" ; then
                rm "$file"                             # No changes
            elif [ -f "$file" ] && [ -s "$file" ]; then
                CygbuildEcho "-- Content of $file"
                lsdiff "$file"
            else
                rm --force "$file"
            fi
        fi
    done < $retval

    CygbuildEcho "-- Done. Examine *.sh and $cygdir/ and *.patch"
}

function CygbuildCmdPrepIsUnpacked()
{
    local id="$0.$FUNCNAME"
    local msg="$1"

    if [ -d "$srcdir" ]; then
        [ "$msg" ] && echo "$msg"
    else
        return 1
    fi
}

function CygbuildCmdPrepPatch()
{
    local id="$0.$FUNCNAME"
    local status=0

    CygbuildIsSourceUnpacked && return 0

    CygbuildPushd
        cd "$TOPDIR" &&
        CygbuildPatchApplyRun ${FILE_SRC_PATCH##*/}
        status=$?
    CygbuildPopd

    return $status
}

function CygbuildCmdShadowDelete()
{
    local id="$0.$FUNCNAME"
    local pfile="$CYGPATCH_DONE_PATCHES_FILE"

    CygbuildVerb "-- Emptying shadow directory" ${builddir#$srcdir/}

    if [[ ! -d "$srcdir" ]]; then
        CygbuildVerb "-- Nothing to do. No directory found: $srcdir"
    else
        if [[ $builddir == *$builddir_relative ]]; then
            rm -rf $builddir/*
        else
            CygbuildDie "-- [FATAL] Something is wrong, this doesn't look" \
                   "like builddir [$builddir]. Aborted."
        fi
    fi
}

function CygbuildCmdShadowMain()
{
    local id="$0.$FUNCNAME"

    CygbuildEcho "== Shadow command"

    if CygbuildIsBuilddirOk ; then
        :
    else
        #    When shadowing, use clean base. Without *.o etc.

        CygbuildPushd

            cd "$srcdir" || exit $?

            CygbuildEcho "-- Running: make clean distclean" \
                         "(ignore errors; if any)"

            if CygbuildIsPythonPackage ; then
                CygbuildRunPythonSetupCmd clean

            elif CygbuildIsRubyPackage ; then
                CygbuildRunRubySetupCmd clean

            else
                make clean distclean
            fi

        CygbuildPopd

        CygbuildVerb "-- Wait, shadowing source files to ${builddir#$srcdir/}"
        CygbuildTreeSymlinkCopy "$srcdir" "$builddir"
        CygbuildVerb "-- Shadow finished."
    fi
}

function CygbuildCmdPrepClean()
{
    local id="$0.$FUNCNAME"

    if [ ! "$TOPDIR" ]; then
        CygbuildDie "$id: TOPDIR not set"
    fi

    #   some archives contain precompiled files like *.o. this
    #   is a mistake which is fixed by removing files.

    CygbuildPushd
        cd "$TOPDIR" || exit $?
        CygbuildCmdCleanMain        "$srcdir"
        CygbuildCmdDistcleanMain    "$srcdir"
        CygbuildCleanConfig         "$srcdir"
    CygbuildPopd
}

function CygbuildCmdPrepMain()
{
    local id="$0.$FUNCNAME"
    local script=$SCRIPT_PREPARE_CYGFILE

    if [ ! "$FILE_SRC_PKG" ]; then
        if ! CygbuildDefineGlobalSrcOrig ; then
            return 1
        fi
    fi

    if [ ! "$REL" ]; then               # Patching fails without this
        CygbuildWarn "$id: [ERROR] RELEASE number is not known."
        return 1
    fi

    local msg="-- [prep] Skipping Cygwin patch; source already unpacked"

    if ! CygbuildCmdPrepIsUnpacked "$msg" ; then
        CygbuildExtractMain         || return $?
        CygbuildCmdPrepPatch        || return $?
    fi

    local status

    CygbuildPushd
        cd "$srcdir" &&
        CygbuildPatchApplyMaybe \
            "patch" \
            "-- [NOTE] applying included patches to sources (if any)"
        status=$?
    CygbuildPopd

    [ ! "$status" = "0" ] && return $status

    CygbuildCmdMkdirs || return $?

    if [ -f "$script" ]; then
        CygbuildEcho "--- External prepare script: $script $TOPDIR"
        CygbuildChmodExec $script
        ${OPTION_DEBUG:+$BASHX} $script "$TOPDIR" || return $?
    else
        CygbuildCmdPrepClean || return $?
    fi
}

function CygbuildCmdDependMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local retval2=$CYGBUILD_RETVAL.$FUNCNAME.tmp

    [ "$CYGCHECK" ] || return 0

    CygbuildEcho "-- Reading objdump direct dependencies"

    find $instdir -name "*.exe" -o -name "*.dll" > $retval

    local list
    [ -s $retval ] && list=$(< $retval)

    if [ ! "$list" ]; then
        CygbuildEcho "-- [NOTE] No *.exe *.dll files found in $instdir"
        return
    fi

    : > $retval       # Clear file

    local file

    for file in $list
    do
        echo "--" ${file#$srcdir/} >> $retval

        CygbuildObjDumpLibraryDepList "$file" | tee -a $retval > $retval.dep
        CygbuildDllToLibName $(< $retval.dep) >> $retval
    done

    if [ -s "$retval" ]; then
        cat $retval
    else
        CygbuildEcho "-- No other dependencies than 'cygwin'"
    fi
}

function CygbuildConfDepend()
{
    local id="$0.$FUNCNAME"

    #  if there is target 'depend' in Makefile, run it.

    CygbuildEcho "-- Running 'make depend'. Ignore possible error message."

    make depend

    return  # return ok status
}

function CygbuildConfOptionAdjustment()
{

    #    All messages must be printed to STDERR because return value
    #    is echoed

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local conf="$srcdir/configure"
    local cygconf="$CYGBUILD_DIR_CYGPATCH_RELATIVE/configure.sh"
    local options="$CYGBUILD_CONFIGURE_OPTIONS"

    if [ ! -f "$conf" ]; then
        return 0
    fi

    if [ "$verbose" ]; then
        awk '/^[ \t]+--with(out)?-/ && ! /PACKAGE|linux/ {
            print
        }' $conf > "$retval"

        if [ -s "$retval" ] ; then
            CygbuildWarn "-- [NOTE] Configure supports additional options:"
            sed 's/^/ /' $retval >&2
        fi
    fi

    local str ret

    for str in $options
    do
        local opt=${str%%=*}      # --prefix=/usr  => --prefix

        local re=""
        local lib=""

        # GNU ./makefile supports --with-PACKAGE options. Check those

        if [[ "$opt" == --with-* ]]; then
            local tmp=${opt%--with-}  # --with-intl
            lib=${opt#$tmp}           # intl
            re="|--with-PACKAGE"
        fi

        if CygbuildGrepCheck "^[^#]*($opt$re)" $conf ; then
            [ "$verbose" ] &&
            CygbuildWarn "-- [INFO] configure supports $opt"

            ret="$ret $str"
        else
            [ "$verbose" ] &&
            CygbuildWarn "-- [NOTE] configure did not support $opt"
        fi
    done

    if [ "$ret" ]; then
        echo $ret
    else
        CygbuildWarn "-- [WARN] ./configure did not support standard" \
            "options. You may need to write custom $cygconf"
        return 1
    fi
}

function CygbuildConfCC()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local conf=$builddir/configure
    local envfile=$EXTRA_CONF_ENV_OPTIONS
    local userOptFile=$EXTRA_CONF_OPTIONS

    local status=0

    if [ ! -f "$conf" ]; then

        CygbuildVerbWarn "-- [WARN] Hm, there is no $conf"

        CygbuildMakefileName "." > $retval
        local make=$(< $retval)

        if [ "$make" ]; then
            CygbuildVerbWarn \
                "-- [WARN] Found only $make Nothing to configure."
        fi

    else

        local opt

        CygbuildConfOptionAdjustment > $retval
        [ -s $retval ] && opt=$(< $retval)

        CygbuildEcho "-- Running ./configure with Cygwin specific options" \
             "${test:+(TEST mode)}"

        if [ -f "$envfile" ]; then
            CygbuildEcho "--- Reading external env: $envfile" \
                 "$envfile $instdir $CYGBUILD_PREFIX $exec_prefix"
            source $envfile || return $?
        fi

        CygbuildConfigureOptionsExtra > $retval
        local extra=$(< $retval)

        opt="$opt $extra"

        #   Libtool gets confused if option --libdir=/usr/lib
        #   is passed during configure. We must check if this package
        #   use libtool and remove that option.

        local makelibtool=$make

        if [ ! "$make" ]; then
            CygbuildMakefileName "." Makefile.am Makefile.in > $retval
            makelibtool=$(< $retval)
        fi

        if [ "$makelibtool" ] &&
           PackageUsesLibtoolMain $makelibtool configure
        then
            CygbuildEcho "-- Hm, package uses libtool; default options" \
                 " --libdir and --datadir are not included"

            local opt cleaned

            for opt in $opt
            do
                if [[ $opt != @(--libdir*|--datadir*) ]]; then
                    cleaned="$cleaned $opt"
                fi
            done

            opt="$cleaned"
        fi

        CygbuildFileReadOptionsMaybe "$userOptFile" > $retval
        local userOptExtra=$(< $retval)

        opt="$opt $userOptExtra"

        if [ "$verbose" ]; then

            #   print the listing more nicely. Get a hand from perl here
            #   to format the option listing

            echo "$opt" |
                perl -ane \
                  "s/\s+/,/g;
                   print '   ', join( qq(\n   ), sort split ',',$_), qq(\n)"
        fi

        if [ ! -x "$conf" ]; then
            CygbuildEcho "-- [NOTE] Making executable" ${conf#$srcdir}
            chmod 755 "$conf"
        fi

        rm -f config.cache

        CygbuildRunShell "$conf" $opt 2>&1 | tee $retval.log
        status=$?

        #   The configure log:
        #     checking how to link with libfoo... /usr/lib/libfoo.a

        if $EGREP "checking how to link.*\<lib[a-z0-9]+\.a\>" \
           $retval.log > $retval.log.out
        then
            CygbuildWarn "-- [WARN] configure uses static libraries"
            cat $retval.log.out
        fi

    fi

    return $status
}

function CygbuildConfPerlCheck()
{
    local id="$0.$FUNCNAME"

    perl -e "use ExtUtils::MakeMaker 6.10"  # at least 6.10 works ok

    local status
    status=$?

    if [ "$status" != "0" ]; then

        cat<<EOF
$id [ERROR] It is not possible to make Perl source package.

Standard Perl (5.8.0) MM:MakeMaker 6.05 does not handle PREFIX variable
correctly to install files into separate directory. Install latest
MakeMaker from <http://search.cpan.org/author/MSCHWERN/ =>
ExtUtils-MakeMaker

  1. Download tar.gz and unpack, chdir to unpack directory
  2. Run: perl Makefile.PL
  3. Run: make install

EOF

        return 1
    fi
}

function CygbuildConfRubyMain()
{
    local root="$instdir"

    local pfx=${1:-$root}
    [ "$1" ] && shift

    CygbuildRunRubySetupCmd \
        config              \
        --prefix=$pfx       \
        --bindir=/usr/bin
}

function CygbuildConfCmakeMain()
{
    local root="$instdir"

    local pfx=${1:-$root}
    [ "$1" ] && shift

    cmake "$srcdir"
}

function CygbuildConfPerlMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local conf="$srcdir/Makefile.PL"
    local envfile=$EXTRA_CONF_ENV_OPTIONS
    local userOptFile=$EXTRA_CONF_OPTIONS
    local status=0

    if [ -f "$conf" ]; then
        CygbuildFileReadOptionsMaybe "$userOptFile" > $retval
        local userOptExtra
        [ -s $retval ] && userOptExtra=$(< $retval)

        local _prefix="/usr"

        (
            cd "$builddir" || exit 1

            #   See http://www.makemaker.org/drafts/prefixification.txt
            #   Do not set: SITEPREFIX  (SITEPREFIX=PREFIX/local)
            #   or PREFIX="$_prefix" because they are set during install

            if [ -f "$envfile" ]; then
                CygbuildEcho "--- Reading external env: $envfile"
                source $envfile || return $?
            fi

            [ "$verbose" ] && set -x

            perl Makefile.PL           \
                  INSTALLDIRS=vendor    \
                  $userOptExtra
        )

        status=$?

    fi

    return $status
}

function CygbuildCmdConfAutomake()
{
    [ -f configure   ]  &&  return 0
    [ -f makefile.am ]  ||  return 0
    [ -f Makefile.am ]  ||  return 0

    local file

    for file in bootstrap autogen.sh
    do
        if [ ! -f $file ]; then
            CygbuildEcho "-- [WARN] [Mm]akefile.am but no file: $file"
        else
            CygbuildEcho "-- No ./configure but looks like automake." \
                         "Running ./$file"

            chmod +x $file
            ./$file

            if [ -f configure ]; then
                CygbuildVerb "-- [OK] ./configure appeared."
            else
                CygbuildEcho "-- [ERROR] No ./configure appeared."
                return 1
            fi
        fi
    done
}

function CygbuildCmdConfConfigFilesCopy()
{
    local id="$0.$FUNCNAME"
    local install="$INSTALL_SCRIPT $INSTALL_FILE_MODES"
    local file done destdir

    for file in $FILE_CONFIG_GUESS $FILE_CONFIG_SUB
    do
        [ -f $file ] || continue

        if [ ! "$done" ]; then
            done=done
            destdir=$(CygbuildFindConfigFileDir)

            CygbuildEcho "-- Copying custom config.{sub,guess} files"

            if [ ! "$destdir" ]; then
                CygbuildWarn "-- [ERROR] Can't locate configu.guess directory"
                return 1
            fi
        fi

        $install "$file" "$destdir"
    done
}

function CygbuildCmdConfBefore()
{
    local id="$0.$FUNCNAME"
    local file="$SCRIPT_CONFIGURE_BEFORE_CYGFILE"

    [ -f "$file" ] || return 0

    #   If there is custom script, run it.
    CygbuildEcho "--- Running external:" ${file#$srcdir/}

    CygbuildChmodExec $file
    ${OPTION_DEBUG:+$BASHX} $file "$builddir"
}

function CygbuildCmdConfMain()
{
    local id="$0.$FUNCNAME"
    local script="$SCRIPT_CONFIGURE_CYGFILE"
    local dummy=$(pwd)      # For debugger
    local status=0

    if ! CygbuildIsBuilddirOk ; then
        CygbuildVerb "-- Hm, no shadow yet. Running it now."
        CygbuildCmdShadowDelete
        CygbuildCmdShadowMain || return $?
    fi

    CygbuildEcho "== Configure command"

    CygbuildPushd

        cd "$builddir" || exit 1

        CygbuildCmdConfConfigFilesCopy
        CygbuildCmdConfAutomake || return 1
        CygbuildCmdConfBefore || return 1

        CygbuildVerb "-- Configuring in" ${builddir#$srcdir/}

        CygbuildMakefileCheck

        if [ -f "$script" ]; then

            CygbuildEcho "--- Running external configure:" ${script#$srcdir/}
            CygbuildChmodExec $script
            ${OPTION_DEBUG:+$BASHX} $script $instdir | CygbuildMsgFilter
            status=$?

        elif CygbuildIsPerlPackage ; then

            CygbuildConfPerlCheck &&
            CygbuildConfPerlMain
            status=$?

        elif CygbuildIsPythonPackage ; then

            CygbuildVerb "-- Python package, nothing to configure"

        elif [ -f configure ]; then

            CygbuildConfCC
            status=$?

        elif CygbuildIsRubyPackage ; then

            CygbuildConfRubyMain

        elif CygbuildIsCmakePackage ; then

            CygbuildConfCmakeMain

        elif CygbuildIsMakefileTarget configure ; then

            #   ./configure generated "Makefile", so this elif must be
            #   after the previous one.

            CygbuildEcho "-- Running: make configure" \
                         "(auto detected; no ./configure)"

            make configure
            status=$?

            #  If that generated the script, we must run it

            if [ "$status" = "0" ] && [ -f configure ]; then
                CygbuildConfCC
                status=$?
            fi

        elif [ -f Imakefile ]; then

            CygbuildEcho "-- Looks like imake(1). Running xmkmf(1)"
            xmkmf

            if [ ! -f Makefile ]; then
                CygbuildEcho "-- Hm, Looks like Xconsoritum package," \
                     "running: xmkmf -a"
                xmkmf -a
            fi

        elif [ -f configure.in ] || [ -f configure.ac ]; then

           CygbuildEcho "-- Running: autoreconf -fi because of" \
                        "./configure.{in,ac}"

           # aclocal
           # automake --add-missing &&
           # autoconf

           autoreconf --force --install &&
               CygbuildConfCC

           status=$?

        else

            CygbuildEcho "-- [NOTE] No ./configre program found."

        fi

    CygbuildPopd

    return $status
}

function CygbuildSetLDPATHpython()
{
    local id="$0.$FUNCNAME"

    #  Make sure all paths are there

    local try="$PYTHON_LIBDIR"

    if  [ ! "$try" ]; then
        CygbuildWarn "-- [WARN] python library dir /usr/lib not defined"
    elif [ -d "$try" ]; then

        if [ "$LD_LIBRARY_PATH" ]; then
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$try"   # global-def
        else
            export LD_LIBRARY_PATH="$try"
        fi

        if [ "$LD_RUN_PATH" ]; then
            export LD_RUN_PATH="$LD_RUN_PATH:$try"     # global-def
        else
            export LD_RUN_PATH="$try"
        fi

        CygbuildVerb "-- [INFO] Added Python to paths " \
                 "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" \
                 "LD_RUN_PATH=$LD_RUN_PATH"

    fi
}

function CygbuildCmdBuildRuby()
{
    local id="$0.$FUNCNAME"
    local status=0

    CygbuildPushd
        cd "$builddir"                                    &&
        CygbuildEcho "-- Building: ruby setup.rb setup"   &&
        CygbuildRunRubySetupCmd setup
        status=$?
    CygbuildPopd

    return $status
}

function CygbuildCmdBuildPython()
{
    local id="$0.$FUNCNAME"
    local status=0

    #  Python *.dll libraries must also have this.
    CYGBUILD_LDFLAGS="-Wl,--no-undefined"

    CygbuildPushd
        CygbuildSetLDPATHpython
        cd "$builddir"                                      &&
        CygbuildEcho "-- Building: python setup.py build"   &&
        CygbuildRunPythonSetupCmd build
        status=$?
    CygbuildPopd

    return $status
}

function CygbuildCmdBuildStdMakefile()
{
    local id="$0.$FUNCNAME"
    local optfile="$EXTRA_BUILD_OPTIONS"
    local status=0

    CygbuildExitIfNoDir "$builddir" "$id: builddir not found: $builddir"

    CygbuildPushd

        cd "$builddir" || exit 1

        local retval="$CYGBUILD_RETVAL.$FUNCNAME"
        CygbuildMakefileName "." > $retval
        local makefile=$(< $retval)

        CygbuildVerb "-- Building with standard make(1) $makefile"

        if [ ! "$makefile" ]; then

            CygbuildWarn "-- [WARN] No Makefile." \
                 "If you already tried [configure]" \
                 "You need to write custom script" \
                 "CYGWIN-PATCHES/build.sh" \
                 "(remember to run [shadow] after changes)"

            status="17"  # Just random number, different from rest

        else

            #   Run in separate shell so that reading configuration
            #   file settings do not interfere currently running process

            local debug
            [[ "$OPTION_DEBUG" > 0 ]] && debug="debug"

            (
                if [ -f "$optfile" ]; then
                    CygbuildEcho "-- Reading extra env from" \
                                 ${optfile#$srcdir/}

                    [ "$verbose" ] && cat $optfile
                    source $optfile || exit $?
                fi

                [ "$debug" ] && set -x

                local dummy=$(pwd)   # For debugging

                local env
                CygbuildShellEnvironenment > $retval
                [ -s $retval ] && env=$(< $retval)

                #   Display version information before compiling
                gcc --version | head --lines=1

                [ "$verbose" ] && set -x

                CygbuildIsCmakePackage && [ "$verbose" ] && env="env VERBOSE=1"

                eval $env make -f $makefile             \
                    AM_LDFLAGS="$CYGBUILD_AM_LDFLAGS"   \
                    $env                                \
                    $CYGBUILD_MAKEFLAGS
            )

            status=$?
        fi

    CygbuildPopd

    return $status
}

function CygbuildCmdBuildMain()
{
    local id="$0.$FUNCNAME"
    local status=0
    local script="$SCRIPT_BUILD_CYGFILE"

    CygbuildEcho "== Build command"

    CygbuildNoticeBuilddirMaybe || return $?
    CygbuildDefineGlobalCompile

    if [ -f "$script" ]; then

        CygbuildEcho "--- Building with external:" \
                 ${script#$srcdir/} $PKG $VER $REL

        CygbuildPushd
            cd "$builddir" || exit 1
            CygbuildChmodExec $script
            $script $PKG $VER $REL | CygbuildMsgFilter
            status=$?
        CygbuildPopd

    elif CygbuildIsPythonPackage ; then

        CygbuildCmdBuildPython
        status=$?

    elif CygbuildIsRubyPackage ; then

        CygbuildCmdBuildRuby
        status=$?

    else

        CygbuildCmdBuildStdMakefile
        status=$?

    fi

    return $status
}

function CygbuildCmdDependCheckMain()
{
    local id="$0.$FUNCNAME"

    CygbuildEcho "-- Checking dependencies in README and setup.hint"

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local module="$CYGBUILD_STATIC_PERL_MODULE"

    [ ! "$module" ] || return 1

    local destdir=$DIR_CYGPATCH
    local file=$destdir/setup.hint

    if [ ! -f "$file" ]; then
        CygbuildDie "-- $id: [ERROR] Can't find $file. Forgot to run [files]?"
    fi

    CygbuildEcho "-- Calling $module::CygcheckDepsCheckMain()"

    local debug=${OPTION_DEBUG:-0}

    #   1. Load library MODULE
    #   2. Call function with parameters.

    perl -e "require qq($module); SetDebug($debug); \
        CygcheckDepsCheckMain( qq($instdir), qq($destdir) );"
}

function CygbuildCmdTestAdditional()
{
    local id="$0.$FUNCNAME"
    local dir="$builddir/$CYGBUILD_DIR_CYGPATCH_RELATIVE/test"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ -d "$dir" ] || return 0    # No additional tests to run

    if [ ! -d "$instdir" ]; then
        CygbuildEcho \
            "-- [INFO] No install dir, skiping additional tests"
        return 0
    fi

    local status=0
    local ret=0

    CygbuildPushd
        cd "$builddir" || CygbuildDie "$id: [builddir] error"

        # This is a simple: include all directories, but exclude a few obvious ones

        find "$instdir" \
            -type d \
            -a ! -path "*/$instdir_relative" \
            -a ! -path "*/usr" \
            -a ! -path "*/doc*" \
            -a ! -path "*/htdoc*" \
            -a ! -path "*/man*" \
            -a ! -path "*/Cygwin*" \
            -printf "%p:" \
            > $retval

        local path=""
        [ -s $retval ] && path=$(< $retval)

        local debug

        [[ "$OPTION_DEBUG" > 0 ]] && debug="debug"

        local test

        for test in $dir/*
        do
            [ -e "$test" ] || continue

            if [ ! -x "$test" ]; then
                CygbuildVerb "--   not executable:" ${test#$builddir/}
                continue
            fi

            CygbuildEcho "-- [INFO]" ${test/$builddir\//}

            # Note: printf() left trailing colon(:) to the end of $path

            if [ "$debug" ] && [[ "$test" == *.sh ]]; then

                PATH="$path$PATH" $BASHX $test
                status=$?
            else
                PATH="$path$PATH" $test
                status=$?
            fi

            if [ $status -ne 0 ]; then
                ret=1
                CygbuildWarn "--   [WARN] Fail $status"
            fi

        done

    CygbuildPopd

    return $ret
}

function CygbuildCmdTestMain()
{
    local id="$0.$FUNCNAME"

    # FIXME Do we have a need to return proper status code?

    CygbuildEcho "== Test command"

    CygbuildPushd
        cd "$builddir" || CygbuildDie "$id: [builddir] error"
        make test 2>&1 | tee $PKGLOG
    CygbuildPopd

    CygbuildCmdTestAdditional
}

function CygbuildCleanConfig ()
{
    # Clean configuration files

    rm --force config.status config.log
}

function CygbuildCmdCleanBasic()
{
    local dir="$1"

    if [ ! "$builddir" ] || [ ! -d "$dir" ]; then
        CygbuildWarn "[WARN] CygbuildCmdCleanBasic() DIR arg is empty"
        return 1
    fi

    find "$dir" \
        -type f \
        \( \
            -name "*.pyc" \
            -o -name "*.exe" \
            -o -name "*.[oa]" \
            -o -name "*.la" \
        \) \
        -print0 \
        | xargs --null --no-run-if-empty echo rm -f
}

function CygbuildCmdCleanMain()
{
    local id="$0.$FUNCNAME"
    local dir=${1:-$builddir}
    local opt="$2"
    local script="$SCRIPT_CLEAN_CYGFILE"

    CygbuildEcho "-- Running 'make clean' (or equiv.) in" ${dir#$srcdir/}

    CygbuildExitIfNoDir $dir "$id: [ERROR] 'dir' does not exist [$dir]"

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    CygbuildMakefileName $dir > $retval
    local makefile=$(< $retval)

    local status=0

    if [ -f "$script" ]; then

        CygbuildEcho "--- Clean with external:" ${script#$srcdir/}

        CygbuildPushd
            cd "$builddir" || exit $?
            CygbuildChmodExec $script
            $script $PKG $VER $REL | CygbuildMsgFilter
            status=$?
        CygbuildPopd

    elif CygbuildIsPythonPackage ; then

        CygbuildMakefileRunPythonInDir "$srcdir" clean

    elif CygbuildIsRubyPackage ; then

        CygbuildRunRubySetupCmd clean

    elif [ ! "$makefile" ]; then

        if [ "$opt" != "nomsg" ]; then
            CygbuildEcho "-- No Makefile found, running basic clean in" \
                ${dir#$srcdir/}

            CygbuildCmdCleanBasic "$dir"
        fi

    else
        CygbuildPushd

            cd "$dir" || exit 1

            make -f $makefile clean ||
            {
                CygbuildVerb "-- [NOTE] Hm, running recursive" \
                             "rm *.o *.exe *.dll instead"
                CygbuildVerb "-- [NOTE] Better, patch the Makefile to include"
                CygbuildVerb "-- [NOTE] target 'clean:'"

                set -o noglob    # Do not expand $CYGBUILD_FIND_OBJS; "*.exe"

                    find . \
                        -type f '(' $CYGBUILD_FIND_OBJS ')' \
                        > $retval

                set +o noglob

                local file

                while read file
                do
                    rm $verbose "$file"
                done < $retval ;

            }
        CygbuildPopd
    fi

    return $status
}

function CygbuildCmdDistcleanMain
{
    local id="$0.$FUNCNAME"
    local dir=${1:-$builddir}
    local opt="$2"

    CygbuildEcho "-- Running 'make distclean' (or equiv.) in" ${dir#$srcdir/}

    local status=0

    if CygbuildIsPythonPackage ; then
        #   Nothing to do
        :
    elif CygbuildIsRubyPackage ; then
        :
    else
        CygbuildMakefileRunTarget "distclean" "$dir" "$opt"
    fi

    return $status
}

function CygbuildCmdCleanByType()
{
    local id="$0.$FUNCNAME"
    local target=$1               # clean, distclean, realclean
    local dir=${2:-$builddir}
    local opt="$3"

    [ ! "$target" ]   && target="clean"

    if [ "$target" = "clean" ]; then
        CygbuildCmdCleanMain
    elif [ "$target" = "distclean" ]; then
        CygbuildCmdDistcleanMain
    else
        CygbuildMakefileRunTarget $target
    fi
}

function CygbuildInstallPackageInfo()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    CygbuildFindDo "$srcdir"        \
        -o -type f                  \
        '('                         \
            -name "*.info"          \
            -o -name "*.info-*"     \
        ')'                         |
        sort > $retval

    local dest="$DIR_INFO"
    local file done

    while read file
    do
        if [ ! "$done" ]; then                # Do only once
            $INSTALL_SCRIPT $INSTALL_BIN_MODES -d "$DIR_INFO" || return 1
            done=1
            CygbuildEcho "-- Installing info files to" \
                         "${dest#$srcdir/}"
        fi

        if [ -f "$file" ]; then
            CygbuildVerb "-- Info file $file"
            $INSTALL_SCRIPT $INSTALL_FILE_MODES $file $dest
        fi
    done < $retval

    # Package must not supply central 'dir' file

    file="$DIR_INFO/dir"

    if [ -f "$file" ] ; then
        rm "$file"   || return 1
    fi
}

function CygbuildInstallTaropt2type ()
{
    #   Convert each --include or --exclude=  option into tar format.

    local type="$1"   # exclude or include
    shift

    local find="--exclude="

    if [ "$type" = "include" ]; then
        find="--include="
    fi

    local ret item

    for item in $*
    do
        if [[ "$item" == $find* ]]; then

            item=${item/--include=}     # Delete this portion

            if [ "$ret" ] && [ "$item" ]; then
                ret="$ret $item"
            else
                ret="$item"
            fi
        fi
    done

    if [ "$ret" ]; then
        echo "$ret"                 # must use quotes, otherwise * expands
    else
        return 1
    fi
}

function CygbuildInstallTaropt2match ()
{
    #   Convert each --exclude=  option into BASH match format.

    local type="$1"   # exclude or include
    shift

    local find="--exclude="

    if [ "$type" = "include" ]; then
        find="--include="
    fi

    local ret item

    for item in "$@"
    do
        if [[ "$item" == $find* ]]; then

            item=${item/$find}     # Delete this portion

            if [[ "$ret"  &&  "$item" ]]; then
                ret="$ret|$item"
            else
                ret="$item"
            fi
        fi
    done

    if [ "$ret" ]; then
        ret="@($ret)"                   # BASH extended match syntax
        echo "$ret"
    else
        return 1
    fi
}

function CygbuildInstallPackageDocs()
{
    local id="$0.$FUNCNAME"
    local dummy                         # For debug
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_FILE_MODES"
    local scriptInstallDir="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"
    local optExclude="$CYGBUILD_TAR_INSTALL_EXCLUDE"

    local dest="$DIR_DOC_GENERAL"

    CygbuildFileReadOptionsMaybe "$EXTRA_TAR_OPTIONS_INSTALL" > $retval
    local optExtra=$(< $retval)

    local docdirInstall="docinstall"
    local docdirGuess="docdirGuess"
    local matchExclude matchInclude tarOptInclude tarOptExclude

    if [ "$optExtra" ]; then

        CygbuildInstallTaropt2match exclude $optExtra > $retval
        [ -s $retval ] && matchExclude=$(< $retval)

        CygbuildInstallTaropt2match include $optExtra > $retval
        [ -s $retval ] && matchInclude=$(< $retval)

        if [[ "$optExtra" == *cygbuild-no-docdir-install* ]]; then
            docdirInstall=
        fi

        if [[ "$optExtra" == *cygbuild-no-docdir-guess* ]]; then
            docdirGuess=
        fi

        CygbuildInstallTaropt2type include $optExtra > $retval
        [ -s $retval ] && tarOptInclude=$(< $retval)

        CygbuildInstallTaropt2type exclude $optExtra > $retval
        [ -s $retval ] && tarOptExclude=$(< $retval)
    fi

    local done name file match

    for file in $builddir/[A-Z][A-Z][A-Z]* \
                $builddir/[Cc]hange[Ll]Log \
                $builddir/[Cc]opyright     \
                $builddir/[Cc]opying       \
                $builddir/[Ll]icense       \
                $builddir/*.html           \
                $builddir/*.pdf            \
                $builddir/*.txt
    do

        [ -f "$file" ] || continue
        [ -s "$file" ] || continue  # Zero length

        name="${file##*/}"
        match=""

        CygbuildMatchPatternList \
            "$file" $CYGBUILD_INSTALL_IGNORE && continue

        if [ "$matchExclude" ] && [[ "$name" == $matchExclude ]]; then
            continue
        fi

        if [ ! "$done" ]; then      #  Do this only once
            CygbuildRun $scriptInstallDir "$dest" || return $?
            done=1
            CygbuildVerb "-- Installing docs to" ${dest#$srcdir/} \
                         ${test:+(TEST MODE)}
        fi

        CygbuildRun $scriptInstallFile $file $dest

    done

    #  tar does not yet support --include options, so do it here

    if [ "$matchInclude" ]; then
        CygbuildPushd

            cd "$builddir"

            # @(<pattern>) => <pattern>

            matchInclude=${matchInclude/\@(}
            matchInclude=${matchInclude/)}
            matchInclude=${matchInclude//\|/ }

            for file in $matchInclude
            do
              [ -f "$file" ] || continue
              CygbuildRun $scriptInstallFile -D $file $dest/$file
            done

        CygbuildPopd
    fi

    #   Next, install whole doc/ Docs/ contrib/ ... directories

    [ "$docdirInstall" ] || return 0

    local dir

    if [ "$docdirGuess" ]; then
        CygbuildDetermineDocDir $builddir > $retval
        [ -s $retval ] || return 0

        dir=$(< $retval)

        [ "$dir" ] || return 0

        if CygbuildIsDirEmpty "$dir" && [ ! "$tarOptInclude" ]; then
            return 0                    #  Nothing to install
        fi
    fi

    CygbuildEcho "-- Installing docs from" ${dir#$srcdir/}

    CygbuildRun $scriptInstallDir $dest || return $?

    #   The relative path "../" is needed, in case of 'cd' command
    #   below.

    local extradir
    [ -d examples ] && extradir="$extradir ${dir:+../}examples"
    [ -d example  ] && extradir="$extradir ${dir:+../}example"
    [ -d sample   ] && extradir="$extradir ${dir:+../}sample"

    CygbuildPushd

        if [ "$dir" ]; then
            cd "$dir" || exit 1
        fi

        #   Remove manual pages, there are already installed in
        #   man/manN/

        local taropt="--extract --no-same-owner --no-same-permissions"
        dummy="test mode: $test"

        if [ "$test" ]; then
            taropt="--list"
        fi

        local status=0

        if [ ! "$test" ] ; then

            dummy="tarOptInclude: $tarOptInclude"
            dummy="dir: $dir"
            dummy="extradir: $extradir"

            if [ "$tarOptInclude" ] || [ "$dir" ] || [ "$extradir" ]
            then
                local group="--group=$CYGBUILD_TAR_GROUP"
                dummy="tarOptExclude: $tarOptExclude"

                tar $optExclude \
                    $tarOptExclude \
                    $verbose \
                    --create $group \
                    --dereference --file=- \
                    ${dir:+"."} \
                    $extradir \
                    $tarOptInclude \
                | ( tar --directory "$dest" $taropt --file=- )

                status=$?
            fi
        fi

    CygbuildPopd

    if [ "$status" != "0" ] && [ "$test" ] ; then
        CygbuildEcho "-- Ignore harmless tar error (TEST MODE)"

    elif [ "$status" != "0" ]; then
        CygbuildWarn "$id: [ERROR] tar failed to move files. " \
             "Need to run [files] or repeat [shadow]?"

        return $status
    fi

    local _dest=${dest#$srcdir/}
    CygbuildVerb "-- Adjusting permissions in $_dest" ${test:+(TEST MODE)}

    find "$dest" -print > $retval

    while read item
    do
        if [ -d "$item" ] || [[ "$item" == $CYGBUILD_MATCH_FILE_EXE ]]
        then
            chmod 755 "$item" || return $?
        else
            chmod 644 "$item" || return $?
        fi
    done < $retval

    return $status
}

function CygbuildInstallExtraManualList()
{
    local id="$0.$FUNCNAME"
    local conf="$EXTRA_MANUAL_FILE"
    local mandest=$instdir/$CYGBUILD_MANDIR_FULL
    local scriptInstallFile="$INSTALL_SCRIPT -D $INSTALL_FILE_MODES"

    [ -f "$conf" ] || return 0

    local item section dest

    while read item section dest
    do

        [ "$item" ] || continue                 # Skip empty lines
        [[ "$item" == [#]* ]] && continue       # Skip comments

        if [[ "$item" == *\** ]]; then          # only glob allowed
            section=
            dest=
        fi

        if [[ $section == */* ]]; then          # Full path
            dest=$section

        elif [ "$dest" ] && [[ ! "$dest" == *.[1-9] ]]; then
            dest=
            CygbuildWarn "-- [WARN] Invalid DEST spec: $dest"
        fi

        local file

        for file in $item               # ITEM Might be a glob
        do
            if [ ! -f "$file" ]; then
                CygbuildWarn "-- [WARN] No such manpage: $file"
                continue
            fi

            if [[ "$dest" == */* ]]; then       # direct install
                dest=${dest#$CYGBUILD_MANDIR_FULL/}
                dest="$mandest/$dest"

                CygbuildEcho "-- Copying manual page" \
                    $file "to" ${destr#$srcdir/}

                $scriptInstallFile "$file" "$dest"
                continue
            fi

            local name=${file##*/}
            local nbr=${name##*.}
            local plain=${name%.$nbr}

            [ "$section" ] || section="$nbr"

            if [[ ! "$section" == [0-9]* ]]; then
                CygbuildWarn "-- [WARN] Invalid section: $file $section"
                continue
            fi

            local manpage="$plain.$section"

            [ "$dest" ] && manpage="$dest"

            local mandir="$mandest/man$section"

            CygbuildEcho "-- Copying manual page" \
                $file "to" ${mandir#$srcdir/}

            $scriptInstallFile "$file" "$mandir/$manpage"

        done
    done < $conf
}

function CygbuildInstallExtraManual()
{
    local id="$0.$FUNCNAME"
    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_FILE_MODES"
    local scriptInstallDir="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"

    local mandest=$instdir/$CYGBUILD_MANDIR_FULL
    local addsect=$CYGBUILD_MAN_SECTION_ADDITIONAL

    local mandir="$DIR_CYGPATCH"
    local try="$DIR_CYGPATCH/man"

    if CygbuildIsDirMatch "$try" *.[0-9]* *.pod ; then
        mandir="$try"
    fi

    if [ -f "$EXTRA_MANDIR_FILE" ]; then
        local dir=DIR_CYGPATCH/$(< $EXTRA_MANDIR_FILE)

        if [ -d "$dir" ]; then
            CygbuildEcho "-- Reading extra dir info from" ${dir#$srcdir/}
            mandir="$dir"
        else
            CygbuildWarn "-- [ERROR] Not a directory '$dir', based on " \
                ${dir#$srcdir/}
        fi

    elif [ -d "$mandir/manpages" ]; then
        mandir="$mandir/manpages"

    elif [ -d "$mandir/man" ]; then
        mandir="$mandir/man"
    fi

    #   Convert Perl pod pages to manuals.

    local done podcopy
    local file page name nbr mansect manpage program dir

    for file in $mandir/*.pod           \
                $mandir/*.[1-9]         \
                $mandir/*.[1-9]$addsect
    do

        [[ $file == *\[*  ]]    && continue # Name was not expanded
        [ ! -f "$file" ]        && continue

        podcopy=

        #  /path/to/program.1x.pod => program.1x.pod
        name=${file##$DIR_CYGPATCH/}

        dir="."

        if [[ $name == */* ]]; then
            dir=${name%%/*}
        fi

        name=${name%.pod}               # program.1x.pod => program.1x
        name=${name##*/}                # <dir>/program => program

        manpage="$dir/$name"

        if [ ! -f "$manpage" ]; then
            manpage=$DIR_CYGPATCH/$dir/$name
        fi

        program=${name%$addsect}        # program.1x => program.1
        program=${program%.[0-9]}       # program.1 => program
        nbr=${name##*.}                 # program.1x => 1x

        if [[ $nbr != [0-9]* ]]; then
            CygbuildDie "$file does not include SECTION number (like *.1*)"
        fi

        if [[ $file == *.pod ]]; then

            if [ ! $done ]; then
                CygbuildEcho "-- Converting *.pod files to manual pages"
                done=1
            fi

            #  Unfortunately pod2man always includes some headers, so it
            #  must be fixed with sed. The manual page name is defined
            #  directly form $file and would loook like PROGRAM.6(SECTION)
            #  when it should read PROGRAM(SECTION)

            pod2man                                                 \
                --section="$nbr"                                    \
                --release="dummy123"                                \
                --center="User Contributed Documentation" $file |   \
                sed  -e 's/dummy123//g'                             \
                     -e "s/$name/$program/ig"                       \
                > $manpage ||                                       \
                return $?

            podcopy="$manpage"
        fi

        #  Copy manual pages to installation directory

        nbr=${nbr%$addsect}
        mansect="$mandest/man$nbr"

        CygbuildEcho "-- Copying external manual page" \
             ${manpage#$srcdir/} "to" ${mandest#$srcdir/}

        $scriptInstallDir  "$mansect"
        $scriptInstallFile "$manpage" "$mansect"

        if [ "$podcopy" ]; then
            #  This was generated and installed, so remove it
            rm -f "$podcopy"
        fi

    done
}

function CygbuildInstallExtraManualCompress()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #  Compress all manual pages

    local instdocdir="$instdir/$CYGBUILD_MANDIR_FULL"

    CygbuildVerb "-- Compressing manual pages" ${test:+(TEST MODE)}

    if [ ! -d "$instdocdir" ]; then
        CygbuildWarn "-- [WARN] Directory not found:" ${instdocdir#$srcdir/}
    else

        find $instdocdir            \
            -type f                 \
            '('                     \
                ! -name "*gz"       \
                -a ! -name "*.bz2"  \
            ')'                     \
            > $retval

        if [ -s $retval ]
        then
            local file

            while read file
            do
                CygbuildCompressManualPage --force --best "$file" || return $?
            done < $retval
        fi

        find $instdocdir -type l -name "*.[1-9]" > $retval

        if [ -s $retval ]
        then
            while read file
            do
                #   If same program is "alias", then we have to rearrange
                #   things a bit
                #
                #       xsetbg.1 -> xloadimage.1
                #
                #   If we compress xloadimage.1.gz, then the link would be
                #   invalid

                CygbuildPushd
                    cd "${file%/*}" || exit $?
                    local name=${file##*/}

                    CygbuildPathAbsoluteSearch $name > $retval
                    path=$(< $retval)

                    if [ "$path" ] && [ -f "$path.gz" ]; then
                        ln --symbolic --force $verbose \
                            "$path.gz" "$name.gz" || exit 1

                        rm "$name"

                    elif [ "$path" ] && [ -f "$path.bz2" ]; then
                        ln --symbolic --force $verbose \
                            "$path.bz2" "$name.bz2" || exit 1

                        rm "$name"
                    fi
                CygbuildPopd

            done < $retval
        fi
    fi
}

function CygbuildInstallExtraMimeFiles()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local file="$FILE_INSTALL_MIME"

    [ -f "$file" ] || return 0

    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_BIN_MODES -D"

    CygbuildEcho "-- Installing mime"

    CygbuildRun $scriptInstallFile ${verbose:+--verbose} \
        "$file" "$instdir/usr/lib/mime/packages/$PKG"
}

function CygbuildInstallExtraChmodBin()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ -d "$instdir" ] || return 1

    CygbuildPushd

    cd "$srcdir"
    local dir=${instdir#$srcdir/}

    # Sometimes Makefiles use cp(1), and not install(1) with
    # proper permissions.

    find "$dir" \
        -type f \
        -name "*.exe" \
        -o -name "*.dll" \
        -o -name "*.sh" \
        -o -name "*.p[yl]" \
        -o -path "*/bin/*" \
        -o -path "*/sbin/*" \
        > "$retval"

    [ -s "$retval" ] || return 0

    CygbuildVerb "-- [INFO] ensuring file permission 755"
    [ "$verbose" ] && cat "$retval"

    cat "$retval" | xargs --no-run-if-empty chmod 755

    CygbuildPopd
}

function CygbuildInstallExtraChmodMain()
{
    CygbuildInstallExtraChmodBin
}

function CygbuildInstallExtraBinFiles()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local extrabindir="$srcdir/$CYGBUILD_DIR_CYGPATCH_RELATIVE/bin"

    [ -d "$extrabindir" ] || return 0

    local scriptInstallFile="$INSTALL_SCRIPT -D"
    local item dest todir tmp _file

    CygbuildEcho "-- Installing external programs from:" \
        ${extrabindir#$srcdir/}

    local item

    for item in $extrabindir/*
    do
        # Ignore these files

        case "$item" in
            *.tmp | *.cyginstdir | *[#~])
                continue
                ;;
        esac

        local _file=${item##*/}
        local _dest=$item.cyginstdir
        local dest="/usr/bin"         # default location
        local perm="$INSTALL_BIN_MODES"

        if [ -f "$_dest" ]; then
            local line _perm found
            while read line _perm
            do
                # Search for first line with path name
                case "$line" in
                    /* )
                        dest=${line%/*}
                        _file=${line##*/}
                        [ "$_perm" ] && perm="--mode=$_perm"
                        found=$line
                        break
                        ;;
                esac
            done < "$_dest"

            if [ ! "$found" ]; then
                CygbuildWarn "-- [WARN] Directory missing in ${_dest#$srcdir/}"
            fi
        else
            tmp=$( awk '/cyginstdir:/ { print $(NF)}' "$item" )

            [ "$tmp" ] && dest=${tmp%/} # Change destination
        fi

        todir="$instdir$dest"

        CygbuildVerb "-- install ${todir#$srcdir/}/$_file"

        CygbuildRun $scriptInstallFile $perm "$item" "$todir/$_file" ||
           return $?
    done
}

function CygbuildInstallExtraMimeFile()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local file="$FILE_INSTALL_MIME"

    [ -f "$file" ] || return 0

    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_FILE_MODES -D"

    CygbuildEcho "-- Installing mime from" ${file#$srcdir/}

    CygbuildRun $scriptInstallFile ${verbose:+--verbose} \
        "$file" "$instdir/usr/lib/mime/packages/$PKG"
}

function CygbuildInstallExtraDirsFile()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local file="$FILE_INSTALL_DIRS"

    [ -f "$file" ] || return 0

    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"

    CygbuildEcho "-- Installing dirs from" ${file#$srcdir/}

    awk '

        $1 ~ /[a-zA-Z]/  &&  $1 !~ /#|^\// {
            print $1
        }

        $1 ~ /^\// {
            print "-- [WARN] Skippped, leading slash: " $1
        }

    ' "$file" > $retval

    if [ ! -s "$retval" ]; then
        CygbuildWarn "-- [WARN] nothing found from:" ${file#$srcdir/}
        return 1
    fi

    local list=$(< $retval)
    local status=0

    CygbuildPushd

        cd "$instdir" &&
        CygbuildRun $scriptInstallFile ${verbose:+--verbose} $list

        status=$?

    CygbuildPopd

    return $status
}

function CygbuildInstallExtraMain()
{
    local id="$0.$FUNCNAME"

    CygbuildInstallExtraManualList       &&
    CygbuildInstallExtraManual           &&
    CygbuildMakeRunInstallFixPerlManpage &&
    CygbuildInstallExtraBinFiles
    CygbuildInstallExtraChmodMain
    CygbuildInstallExtraMimeFile
}


function CygbuildInstallFixManSymlinks()
{
    local id="$0.$FUNCNAME"
    local mandir="$builddir/usr/share/man"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ -d "$mandir" ] || return 0

    find -L "$mandir" \
        -type l \
        -path "*/man/*" \
        > $retval

    [ -s $retval ] || return 0

    CygbuildVerb "-- Fixing manual page symlinks"

    CygbuildPushd

        local file

        while read file
        do
            local path=${file%/*}

            cd "$path" || continue

            local name=${file##*/}
            local dest=$( ls -l $name | awk '{print $(NF) }' )  # Symlink is the last word

            [ -f "$dest" ] && continue

            local orig="$dest.gz"

            if [ -f "$orig" ]; then
                CygbuildVerb "-- [NOTE] Correcting $name -> $orig"
                rm "$name"
                ln --symbolic "$orig" "$name.gz"
            else
                CygbuildVerb "   [WARN] Don't know how to correct: $name"
            fi
        done < $retval

    CygbuildPopd
}

function CygbuildInstallFixMandir()
{
    local id="$0.$FUNCNAME"
    local mandir="$dir/usr/man"

    [ -d "$mandir" ] || return 0

    CygbuildVerb "-- Fixing manual page locations"

    local todir="$CYGBUILD_PREFIX/$CYGBUILD_MANDIR_RELATIVE"
    local manroot="$instdir$todir"
    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_FILE_MODES"
    local scriptInstallDir="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"

    $scriptInstallDir "$manroot" || return 1

    local item

    for item in $mandir/*
    do
      mv "$item" "$manroot"
    done

    rmdir "$dir/usr/man"
}

function CygbuildInstallFixPermissions()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    find "$instdir" -type f > $retval
    [ -s $retval ] || return 0

    local file exeList readList

    while read file
    do
      if [[ "$file" == $CYGBUILD_MATCH_FILE_EXE ]] ||
         [[ "$file" == */bin/*  ]] ||
         [[ "$file" == */sbin/* ]]
      then

          exeList="$exeList $file"

      elif [[ "$file" == */man/* ]]; then

          readList="$readList $file"

      fi
    done < $retval

    [ "$exeList"  ] && chmod 755 $exeList
    [ "$readList" ] && chmod 644 $readList
}

function CygbuildInstallFixFileExtensions()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    find "$instdir/usr/bin" "$instdir/usr/games" \
        -type f             \
        -name "*.rb"        \
        -o -name "*.py"     \
        -o -name "*.pl"     \
        > $retval           \
        2> /dev/null

    [ -s $retval ] || return 0

    local file name new re regexp

    while read file
    do
        CygbuildEcho "-- [NOTE] Removing extension from" ${file#$instdir/}

        name=${file##*/}
        new=${file%.*}
        mv "$file" "$new"

        CygbuildStrToRegexpSafe "$name" > $retval.re
        re=$(< $retval.re)

        if [ "$regexp" ]; then
            regexp="$regexp|\<$re\>"
        else
            regexp="\<$re\>"
        fi

    done < $retval

    #   See if the above change needs chnages in documentation

    local dir=${instdir#$srcdir}

    $EGREP --recursive --files-with-matches \
        "$regexp"                           \
        "$dir/usr/share/doc"                \
        > $retval                           \
        2> /dev/null

    #   FIXME: bz2?
    zgrep "$regexp" "$dir/usr/share/man*/*" \
        >> $retval                          \
        2> /dev/null

    [ -s $retval ] || return 0

    CygbuildWarn "-- [WARN] Docs that refer to files with the extention"
    sed "s,$srcdir,," $retval
}

function CygbuildInstallFixInterpreterPerl ()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local bin="$PERLBIN"
    local file="$1"
    local _file=${file#$srcdir/}

    if [ ! "$file" ] || [ ! -f "$file" ] ; then
        CygbuildWarn "$id: No such file: $file"
        return 1
    fi

    #  Clean lines:
    #
    #    #!/usr/bin/perl5.8.8
    #    #!/usr/bin/perl -*-
    #
    #    eval 'exec /usr/bin/perl -w -S $0 ${1:+"$@"}'
    #      if 0; # not running under some shell
    #
    #  Or even like this:
    #
    #    #!/usr/bin/perl -w
    #
    #    # the path to perl at the top was generated by autoconf
    #
    #    #!/usr/bin/perl -w

    local max=10

    head --lines=$max "$file" > $retval
    $EGREP '^#![[:space:]]*/.*perl' $retval > $retval.grep

    wc -l < $retval.grep > $retval.count
    local count=$(< $retval.count)

    if [ $count -gt 1 ] ; then
        CygbuildEcho "-- [NOTE] Fixing multiple shebang lines in $_file"

        [ "$verbose" ] && cat $retval.grep

        awk '
            NR < max  &&  /#!.*perl/ {
                if ( ! done )
                    print
                done = 1
                next
            }
            {
                print
            }
        ' max=$max "$file" > $retval.awk &&
        mv --force $retval.awk "$file"
    fi

    sed -e "1s, -[*]*-.*,,"                             \
         -e "1s,\(#!.*$bin\)\([0-9].*\),\1,"            \
         -e "1s,#!.* \(.*\),#!$bin \1,"                 \
         -e "/.*eval.*exec.*bin\/perl.*/d"              \
         -e "/.*not running under some shell/d"         \
         "$file" > $retval

    if [ -s $retval ] &&
       CygbuildFileCmpDiffer "$file" $retval
    then
        CygbuildEcho "-- [NOTE] Fixing Perl call line in $_file"
        [ "$verbose" ] && diff "$file" $retval
        mv --force $retval "$file"
    fi
}

function CygbuildInstallFixInterpreterGeneric()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local bin="$1"
    local file="$2"

    local name=${bin##*/}

    if [ ! "$file" ] || [ ! -f "$file" ] ; then
        CygbuildWarn "$id: No such file $file"
        return 1
    fi

    #  /usr/bin/env python
    #  sed => /bin/python python
    #  sed => /bin/python

    sed -e "1s,#!.* \(.*\),#!$bin \1," \
        -e "1s,\($name\)[ \t]\+\1,\1," \
        "$file" \
        > "$retval" &&

    if [ -s "$retval" ] &&
        CygbuildFileCmpDiffer "$file" "$retval"
    then
        [ "$verbose" ] && diff "$file" "$retval"
        mv --force "$retval" "$file"
        CygbuildEcho "-- [NOTE] Fixed shebang call line"
    fi
}

function CygbuildInstallFixDocdirInstall()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$instdir"
    local dest="$DIR_DOC_GENERAL"
    local dest1=${dest##*/}                 # Delete path. Basename
    local pwd="$(pwd)"

    if [ "$test" ]; then
        CygbuildEcho "-- Handling of doc/foo-N-N/ directory (TEST MODE)"
        return 0
    fi

    [ -d "$dest" ] || return 0

    #   Clean any empty directories

    find "$dest" -type d > $retval

    if [ -s $retval ]; then
        local tmp

        while read tmp
        do
            if CygbuildIsDirEmpty "$tmp" ; then
                CygbuildVerb "-- Removing empty directory" \
                             ${tmp#$pwd/}
                rmdir "$tmp"
            fi
        done < $retval
    fi

    #   The Makefile may install in:
    #
    #       .inst/usr/share/doc/foo/
    #
    #   But for Cygwin, this must be:
    #
    #       .inst/usr/share/doc/foo-0.10.3/

    CygbuildStrToRegexpSafe "$dest1" > $retval   # 1.20+r100 etc.
    local re=$(< $retval)

    local pdir=$(
        cd "$dir/usr/share/doc" &&
        { ls | $EGREP --invert-match "$re|Cygwin" ; }
    )

    [ "$pdir" ] || return 0

    local pkgdocdir="$dir/usr/share/doc/$pdir"

    if [[ "$pdir" == *\ * ]]; then
        #  Multiple directories or space in directory name.
        CygbuildEcho "-- [NOTE] Handle manually. Can't relocate: $pkgdocdir"
        return 0
    fi

    local group="--group=$CYGBUILD_TAR_GROUP"

    if ! ${test:+echo} tar --directory "$pkgdocdir" --create --file=- \
         $group . |
         {
            mkdir -p "$dest"                                    &&
            tar --directory "$dest" --extract \
                --no-same-owner --no-same-permissions --file=-  &&
            rm -rf "$pkgdocdir" ;
         }
    then

        [ ! "$test" ] &&
        CygbuildWarn "$id: [ERROR] Internal error while relocating" \
                     ${pkgdocdir#$srcdir/}
        return 99
    fi

    CygbuildEcho "-- [NOTE] Moving ${pkgdocdir#$pwd/} to" \
                 ${dest#$dir/}
}

function CygbuildInstallPostinstallPartInfo()
{
    local id="$0.$FUNCNAME"
    local dest="$DIR_DEFAULTS_GENERAL"
    local i list

    for i in "$@"
    do
        i=${i##*/}          # Delete path
        list="$list $i"
    done

    local commands="\
(
    cd /usr/share/info &&
    for i in $list
    do
        install-info --dir-file=./dir --info-file=\$i
    done
)"

    CygbuildPostinstallWriteMain "info" "$commands"
}

function CygbuildInstallPostinstallPartEtc()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dest="$DIR_DEFAULTS_GENERAL"

    CygbuildEcho "-- Writing /etc postinstall script"

    #   Do we have a single file or directory?
    #   The SED call filters out leading/path/to/etc

    find "$dest" \
        ! -path $dest \
        -a ! -name preremove \
        -a ! -name postinstall \
        > $retval

    local item list

    while read item
    do
        if [ -d "$item" ]; then
            item="$item/"               # Append slash
        fi

        item=${item#$dest/}

        list="$list $item"
    done < $retval

    [ "$list" ] || return 0

    local commands="\
fromdir=/etc/defaults
for i in $list
do
    from=\"\$fromdir/\$i\"
    to=\"\$dest/\$i\"

    [ -e \"\$from\" ] || continue
    [ -e \"\$to\"   ] && continue

    case \"\$i\" in
        */) # Directory
            install -d -m 755 \"\$to\"
            ;;
        *)  # File
            install -v -m 644 \"\$from\" \"\$to\"
            ;;
    esac
done
"

    CygbuildPostinstallWriteMain "etc" "$commands"
}

function CygbuildInstallFixInfoInstall()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$instdir/usr/share/info"

    [ -d "$dir" ] || return 0

    find $instdir/usr/share/ -name "*.info" \
        > $retval 2> /dev/null

    [ -s $retval ] || return 0          # No info files

    CygbuildInstallPostinstallPartInfo $(< $retval)
}

function CygbuildInstallFixEtcdirInstall()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$instdir"

    #   The Makefile may install files in:
    #
    #       .inst/etc/<package>/
    #
    #   But for Cygwin, this must be reloaced + have postinstall
    #
    #       .inst/etc/default/<package/
    #
    #   Check if there is anything to install

    if [ -d "$dir/usr/etc" ]; then
        CygbuildWarn "   [ERROR] Wrong etc location ${dir#$srcdir}usr/etc"
    fi

    local pkgetcdir=$(
        cd "$dir/etc" 2> /dev/null &&
        ls | head -1
    )

    [ "$pkgetcdir" ] || return 0

    #    Check if there are any files, or non-zero length files
    #    excluging (.keep) and some such.
    #
    #    If it's just a directory structure to be ready for
    #    user to populate, there no need for postinstall etc.

    local item found

    for item in $(find $dir/etc/$pkgetcdir -type f)
    do
        if [ -s "$item" ]; then
            found="live etc files"
            break
        fi
    done

    [ "$found" ] || return 0

    #   Preserve these:
    #
    #       .inst/etc/preremove
    #       .inst/etc/postinstall
    #
    #   and move everything else into
    #
    #       .inst/etc/defaults/etc

    local directory list

    for directory in preremove postinstall
    do
        if [ -d "$dir/etc/$directory" ]; then
            list="$list $directory"
        fi
    done

    local ptar="$retval.pre-post.tar"
    local group="--group=$CYGBUILD_TAR_GROUP"

    if [ "$list" ]; then
        ${test:+echo} tar               \
        --directory "$dir/etc"          \
        --create                        \
        $group                          \
        --file=$ptar                    \
        $list
    fi

    local tar="$retval.tar"

    #   All the rest files
    ${test:+echo} tar                   \
        --directory "$dir/etc"          \
        --create                        \
        $group                          \
        --file=$tar                     \
        --exclude=*preremove*           \
        --exclude=*postinstall*         \
        .

    #   Now recreate the directory structure for Cygwin
    ${test:+echo} rm -rf "$dir/etc"/*

    if [ -f "$ptar" ]; then
        ${test:+echo} tar --directory "$dir/etc" --extract \
                      --no-same-owner --no-same-permissions --file=$ptar
    fi

    if [ -s "$tar" ]; then

        local dest="$DIR_DEFAULTS_GENERAL/etc"

        ${test:+echo} mkdir --parents "$dest"   &&
        ${test:+echo} tar --directory "$dest" --extract \
                      --no-same-owner --no-same-permissions --file=$tar

        if [ ! "$?" = "0" ]; then
            [ ! "$test" ] &&
            CygbuildWarn "$id: [ERROR] error while relocating $pkgetcdir"
            return 99
        fi
    fi

    CygbuildEcho "-- [NOTE] Moving ${pkgetcdir#$(pwd)/} to" \
                 ${DIR_DEFAULTS_GENERAL#$dir/}

    CygbuildPreRemoveWrite
    CygbuildInstallPostinstallPartEtc
}

function CygbuildInstallFixInterpreterMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local plbin="$PERLBIN"
    local pybin="$PYTHONBIN"
    local rbbin="$RUBYBIN"

    find $instdir/usr/{bin,share,lib}   \
        -type f                         \
        > $retval.list                  \
        2> /dev/null

    [ -s $retval.list ] || return 0

    local file

    while read file
    do
        [ -f "$file" ] || continue

        local _file=${file#$srcdir/}       # relative path

        head --lines=1 "$file" > $retval 2> /dev/null

        if $EGREP --quiet "#.*perl" $retval &&
         ! $EGREP --quiet "$plbin[[:space:]-]*$" $retval
        then
            CygbuildVerb "-- [NOTE] Possibly suspicious Perl call" \
                "in $_file: $(cat $retval)"

            CygbuildInstallFixInterpreterPerl "$file"

        elif $EGREP --quiet "#.*python"             $retval &&
           ! $EGREP --quiet '^[[:space:]]*[\"]'     $retval &&
           ! $EGREP --quiet "$pybin([[:space:]]|$)" $retval
        then
            CygbuildEcho "-- [NOTE] Possibly suspicious Python call" \
                 "in $_file: $(cat $retval)"

            CygbuildInstallFixInterpreterGeneric "$pybin" "$file"

        elif $EGREP --quiet "ruby" $retval &&
           ! $EGREP --quiet "$rbbin[[:space:]]*$" $retval
        then

            CygbuildInstallFixInterpreterGeneric "$rbbin" "$file"
        fi

    done < $retval.list
}

function CygbuildInstallFixPerlPacklist()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local file

    # .inst/usr/lib/perl5/site_perl/5.8/cygwin/auto/<pkg>/.packlist

    for file in $instdir/usr/lib/perl5/*/*/*/*/*/.packlist
    do
        [ -f "$file" ] || continue

        local _file=${file#$srcdir/}       # relative path

        CygbuildVerb "-- Adjusting $_file"

        #  Remove the "path/to/.inst" portion

        sed "s/.*$instdir_relative//" "$file" > "$retval" &&
        mv --force "$retval" "$file"
    done
}

function CygbuildInstallFixMain()
{
    CygbuildInstallFixDocdirInstall
    CygbuildInstallFixEtcdirInstall
    CygbuildInstallFixInfoInstall
    CygbuildInstallFixInterpreterMain
    CygbuildInstallFixPerlPacklist
    CygbuildInstallFixMandir
    CygbuildInstallFixFileExtensions
    CygbuildInstallFixPermissions
}

function CygbuildInstallCygwinPartPostinstall()
{
    local id="$0.$FUNCNAME"

    local file=$SCRIPT_POSTINSTALL_CYGFILE
    local dest=$SCRIPT_POSTINSTALL_FILE

    if [ -f "$file" ]; then
        local scriptInstallDir="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"
        local scriptInstallBin="$INSTALL_SCRIPT $INSTALL_BIN_MODES"

        local tofile="$dest/$PKG.sh"

        CygbuildEcho "-- Installing postinstall script to" \
                     "directory ${tofile#$srcdir/}"

        $scriptInstallDir $dest
        $scriptInstallBin $file $tofile
    fi
}

function CygbuildInstallCygwinPartMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local scriptInstallFile="$INSTALL_SCRIPT $INSTALL_FILE_MODES"
    local scriptInstallDir="$INSTALL_SCRIPT $INSTALL_BIN_MODES -d"

    local file
    CygbuildDetermineReadmeFile > $retval &&
    file=$(< $retval)

    if [ ! "$file" ]; then
        CygbuildDie "-- [FATAL] Can't find Cygwin specific $PKG.README file" \
            "Please run command [files]"
    fi

    #   NOTE: the *.README file does not include RELEASE, just VERSION.

    local item

    for item in \
      "required $file  $DIR_DOC_CYGWIN $PKG.README" \
      "optional $SCRIPT_PREREMOVE_CYGFILE   $DIR_PREREMOVE_CYGWIN $PKG.sh" \
      "optional $FILE_PREREMOVE_MANIFEST_TO $DIR_PREREMOVE_CYGWIN $PKG-$CYGBUILD_FILE_MANIFEST_TO" \
      "optional $FILE_PREREMOVE_MANIFEST_FROM $DIR_PREREMOVE_CYGWIN $PKG-$CYGBUILD_FILE_MANIFEST_FROM" \
      "optional $FILE_POSTINSTALL_MANIFEST_DATA $DIR_POSTINSTALL_CYGWIN $PKG-$CYGBUILD_FILE_MANIFEST_DATA"
    do
        set -- $item

        local mode=$1
        local fromfile=$2
        local todir=$3
        local tofile="$todir/$4"

        if [ "$mode" = "required" ] && [ ! -f "$fromfile" ]; then
            CygbuildWarn "$id: [ERROR] Missing file/dir: $fromfile"
            return 1
        fi

        [ -f "$fromfile" ] || continue

        CygbuildRun $scriptInstallDir   $todir              || return $?
        CygbuildRun $scriptInstallFile  $fromfile $tofile   || return $?
    done
}

function CygbuildCmdInstallCheckMain()
{
    local name="libcheck.sh"
    local lib="$CYGBUILD_PROG_LIBPATH/lib/$name"

    CygbuildEcho "== Checking content of installation in" ${instdir#$srcdir/}

    if [ ! -f $lib ]; then
        CygbuildEcho "-- [WARN] Not available: $lib"
        return 0
    fi

    . $lib || return $?
    CygbuildCmdInstallCheckEverything
}

function CygbuildCmdInstallDirClean ()
{
    local id="$0.$FUNCNAME"
    local dir=$instdir

    if [ ! "$dir" ]; then
        CygbuildDie "$id: [ERROR] Internal error. \$instdir is empty"
    fi

    if [ -d "$dir" ]; then

        #  rm -rf is too dangerous to run without a check

        if [[ "$dir" == *$instdir_relative* ]]; then

            #   If other terminal is in this directory, this may fail.

            CygbuildVerb "-- Emptying" ${dir#$srcdir/}

            rm -rf $dir/*

            if [ "$?" != "0" ]; then
                CygbuildDie "-- [ERROR] Is some other terminal/window" \
                       "accessing the directory?"
            fi

        else
            CygbuildDie "$id: [ERROR] Suspicious \$instdir '$dir'"
        fi
    fi
}

function CygbuildCmdInstallFinishMessage()
{
    local relative=${instdir#$srcdir/}

    if [ "$verbose" ]; then
        CygbuildEcho "-- Content of: $relative"
        find -L ${instdir#$(pwd)/} -print
    else
        [ "$test" ] ||
        CygbuildIsGbsCompat ||
        CygbuildEcho "-- See also: find $relative -type f | sort"
    fi
}

function CygbuildCmdInstallPatchVerify()
{
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local file="$CYGPATCH_DONE_PATCHES_FILE"

    CygbuildPatchFileList > $retval

    if [ -s "$retval" ] && [ ! -f "$file" ]; then
        CygbuildWarn "-- [WARN] Patches are not applied"

        [ "$verbose" ] && cat "$retval"

        return 1
    fi
}

function CygbuildCmdDeleteListExists()
{
    local file="$FILE_DELETE_LST"

    [ -f "$file" ]
}

function CygbuildCmdDeleteList()
{
    local file="$FILE_DELETE_LST"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ -f "$file" ] || return 0

    CygbuildEcho "-- Installing with external:" \
                 "${file#$srcdir/}"

    local out=$retval.lst
    local docdir="usr/share/doc/$PKG"

    #  Remove comments and substitute variables

    sed -e 's,#.*,,' \
        -e "s,\$PKG,$PKG," \
        -e "s,\$DOC,$docdir," \
        -e "s,\$VER,$VER," \
        -e '/^[[:space:]]*$/d' \
        $file > $out

    local status=0

    CygbuildPushd

    cd "$instdir" || return $?

    local item options

        while read item options
        do
            ${test:+echo} rm $verbose $options $item
        done < $out

    CygbuildPopd
}

function CygbuildCmdInstallListExists()
{
    local file="$FILE_INSTALL_LST"

    [ -f "$file" ]
}

function CygbuildCmdInstallList()
{
    local file="$FILE_INSTALL_LST"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    [ -f "$file" ] || return 1

    CygbuildEcho "-- Installing with external:" \
                 "${file#$srcdir/}"

    local out=$retval.lst
    local docdir="usr/share/doc/$PKG"

    #  Remove comments and substitute variables

    sed -e 's,#.*,,' \
        -e "s,\$PKG,$PKG," \
        -e "s,\$DOC,$docdir," \
        -e "s,\$VER,$VER," \
        -e '/^[[:space:]]*$/d' \
        $file > $out

    if $EGREP "[$]" $out > $retval; then
        CygbuildWarn "-- [WARN] Unknown substitution variable"
        sed -e "s,$srcdir/,," -e 's/^/   /;' $retval
    fi

    local line=0
    local status=0

    local from to mode

    while read from to mode
    do

        line=$(( line + 1 ))

        local dummy="from:$from to:$to"         # for debugging only
        local origfrom="$from"

        [ "$from" ] || continue                 # Empty line
        [[ "$from" == [#]* ]] && continue       # Skip comments

        local name="$from"
        local ext                               # .sh .pl .1 .5 etc.

        if [[ "$from" == *.* ]]; then
            ext=${from##*.}
            [ "$ext" ] && name=${from%.$ext}    # Without extension
        fi

        ################################################ default locations ###

        if [ ! "$to" ]; then
            # location of manual pages etc. need not to be specified

            case "$from" in
                *.[1-8])
                    to="usr/share/man/man$ext/"
                    ;;

                *.sh | *.pl | *.py)
                    to="usr/bin/$name"
                    ;;

                *.txt)
                    to="$docdir"
                    ;;

                *)
                    CygbuildWarn "$id: [WARN] skipped unknown entry: $from"
                    continue
                    ;;
            esac
        fi

        if [ ! "$mode" ] ; then
            case "$to" in
                */bin/*)
                    mode=755
                    ;;
                *)
                    mode=644
                    ;;
            esac
        fi

        ################################################# special keywords ###

        if [[ "$from" == "mkdir" ]] ; then

            if [[ "$to" == /* ]]; then
                CygbuildWarn "-- [WARN] mkdir skipped," \
                    "extra leading slash in line $line: $to"
                continue

            elif [[ ! "$to" == */ ]]; then
                CygbuildWarn "-- [WARN] mkdir skipped," \
                    "missing trailing slash in line $line: $to"
                continue
            fi

            local path="$instdir/$to"

            ${test:+echo} mkdir ${verbose:+--verbose} -p "$path"

            continue

        elif [[ "$from" == "ln" ]] ; then

            from="$to"
            to="$mode"

            if [[ ! "$from" == */* ]]; then
                CygbuildWarn "-- [WARN] ln skipped," \
                    "SOURCE is not a valid path in line $line: $from"
                continue

            elif [[ "$from" == /* ]]; then
                CygbuildWarn "-- [WARN] ln skipped," \
                    "SOURCE has extra leading slash in line $line: $from"
                continue

            elif [[ "$from" == */ ]]; then
                CygbuildWarn "-- [WARN] ln skipped," \
                    "SOURCE has extra trailing slash in line $line: $form"
                continue
            fi

            local dir=${from%/*}
            local name=${from##*/}
            local path="$instdir/$dir/$name"

            if [ ! -e "$path" ]; then
                 CygbuildWarn "-- [WARN] ln skipped," \
                     "SOURCE does not exist: $instdir_relative/$dir/$name"
            fi

            CygbuildPushd

                cd "$instdir/$dir" &&
                ${test:+echo} ln --symbolic ${verbose:+--verbose} "$name" "$to"

            CygbuildPopd

            continue
        fi

        ######################################################### validity ###

        if [[ "$to" == /* ]] ; then
            CygbuildWarn "$id: [WARN] Skipped." \
                "Leading slash not allowed in DEST, in line $line: $to"
            continue

        elif [[ "$to" == */ ]]; then
            ${test:+echo} install ${verbose+--verbose} -m 755 -d $instdir/$to

        elif [[ "$to" == */* ]]; then
            local dir=${to%/*}
            ${test:+echo} install ${verbose+--verbose} -m 755 -d $instdir/$dir

        else
            CygbuildWarn "$id: [WARN] Skipped." \
                "Invalid entry in line $line: $from $to $mode"
            continue
        fi

        ############################################################ do it ###

        # Remove common suffixes

        local name=$from
        name=${name%.sh}
        name=${name%.pl}
        name=${name%.py}

        # remove CYGWIN-PATCHES

        name=${name#CYGWIN-PATCHES/conf/}
        name=${name#CYGWIN-PATCHES/doc/}
        name=${name#$to}

        local tofile="$instdir/$to"

        if [[ "$to" == */ ]]; then
            to=${to%/}                  # No trailing slash
            tofile="$instdir/$to/${name##*/}"
        fi

        local source="$builddir/$from"

        if [[ "$source" == *\** ]]; then  # Check if contains glob "*"
            tofile=""                     # This is no simple install. Reset.
            unset tofile
        fi

        local todir="$instdir/$to"

        if [ -d "$source" ]; then               # Copy whole directory

            if [[ ! "$source" == */ ]]; then
                CygbuildWarn "-- [WARN] Skip, SOURCE dir does not end" \
                    "in a slash: $source"
                continue
            fi

            # Copy everything under SOURCE inside TO

            CygbuildEcho "-- [NOTE] installing whole directory: $origfrom"

            ${test:+echo} $INSTALL_SCRIPT ${verbose+--verbose} \
                --mode=$mode -d "$todir"

            ${test:+echo} tar --dereference --directory="$source" \
                --create --file=- . |
            ${test:+echo} tar --dereference --directory="$todir" --extract \
                --file=- ||
            status=$?

        else

            local cmd="${test:+echo} $INSTALL_SCRIPT ${verbose+--verbose}"

            for item in $source
            do
                $cmd --mode=755 -d "$to" || status=$?
                $cmd --mode=$mode "$item" "$todir" || status=$?
            done
        fi

    done < $out

    return $status
}

function CygbuildCmdInstallMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    local scriptInstall="$SCRIPT_INSTALL_MAIN_CYGFILE"
    local scriptAfter="$SCRIPT_INSTALL_AFTER_CYGFILE"
    local thispath="$CYGBUILD_PRG_FULLPATH"

    CygbuildEcho "== Install command"

    CygbuildExitIfNoDir "$builddir" \
              "$id: [ERROR] No builddir $builddir." \
              "Did you run [mkdirs] and [shadow]?"

    if [ ! -d "$instdir" ]; then
        mkdir $verbose "$instdir" || exit $?
    fi

    CygbuildCmdInstallPatchVerify
    CygbuildCmdInstallDirClean

    CygbuildPushd

        cd "$builddir" || exit 1

        CygbuildInstallExtraDirsFile

        CygbuildInstallPackageDocs      &&
        CygbuildInstallPackageInfo      &&
        CygbuildInstallCygwinPartMain
        status=$?

        if [ "$status" != "0" ]; then
            local dummy="$id: FAILURE RETURN"       # For debug
            CygbuildPopd
            return $status
        fi

        if [ -f "$scriptInstall" ]; then

            mkdir --parents $verbose "$instdir"

            CygbuildEcho "--- Installing with external:" \
                         "${scriptInstall#$srcdir/}" \
                         "$instdir" \
                         "$thispath"

            CygbuildChmodExec "$scriptInstall"
            "$scriptInstall" "$instdir" "$thispath" | CygbuildMsgFilter
            status=$?

            if [ "$status" != "0"  ]; then
                CygbuildExit $status \
                    "$id: [ERROR] Failed to run $scriptInstall $instdir"
                exit $status
            fi

        else

            CygbuildVerb "-- Running install to" \
                ${dir#$srcdir/} \
                ${test:+(TEST MODE)}

            if CygbuildCmdInstallListExists ; then
                CygbuildCmdInstallList ||
                {
                    status=$?
                    CygbuildPopd
                    return $status
                }
            else
                CygbuildMakefileRunInstallMain ||
                {
                    status=$?
                    CygbuildPopd
                    return $status
                }
            fi
        fi

        if CygbuildCmdDeleteListExists ; then
            CygbuildCmdDeleteList ||
            {
                status=$?
                CygbuildPopd
                return $status
            }
        fi

        dummy="$srcdir"             # For debug only

        CygbuildExitIfNoDir "$srcdir" "$id: [ERROR] srcdir not found"

        dummy="END OF $id"

    CygbuildPopd

    CygbuildInstallExtraMain
    CygbuildInstallFixMain
    CygbuildInstallCygwinPartPostinstall
    CygbuildInstallExtraManualCompress
    CygbuildInstallFixManSymlinks

    if [ -f "$scriptAfter" ]; then

        CygbuildEcho "--- Running external:" \
             ${scriptAfter#$srcdir/} \
             "$instdir"     \
             "$PKG"         \
             "$VER"         \
             "$thispath"

        # local path="$CYGBUILD_PRG_FULLPATH"

        CygbuildChmodExec $scriptAfter

        CygbuildRun ${OPTION_DEBUG:+$BASHX} \
            $scriptAfter        \
                "$instdir"      \
                "$PKG"          \
                "$VER"          \
                "$thispath"     |
        CygbuildMsgFilter ||
        {
            status=$?
            return $status
        }
    fi

    CygbuildCmdInstallFinishMessage
}

function CygbuildCmdScriptRunMain()
{
    local id="$0.$FUNCNAME"
    local script="$1"

    CygbuildEcho "-- Running" ${script#$srcdir/} ${instdir#$srcdir/}

    if [ -f "$script" ]; then

        local cmd=${OPTION_DEBUG:+"sh -x"}
        CygbuildRun $cmd $script $instdir

        if [ "$OPTION_DEBUG" ]; then

            #   postinstall usually runs the installed for info(1)
            #   files. Show the results if this dir exists.

            local dir=$instdir$CYGBUILD_INFO_FULL

            if [ -d "$dir" ]; then
                CygbuildEcho "-- [DEBUG] Content of info 'dir'"
                find "$dir" -print
                cat "$dir/dir"
            fi
        fi
    fi
}

function CygbuildCmdPreremoveInstallMain()
{
    CygbuildCmdScriptRunMain "$SCRIPT_PREREMOVE_CYGFILE"
}

function CygbuildCmdPostInstallMain()
{
    CygbuildCmdScriptRunMain "$SCRIPT_POSTINSTALL_CYGFILE"
}

function CygbuildCmdStripMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$instdir"

    CygbuildExitIfNoDir "$dir" "$id: [ERROR] instdir [$instdir] not found"

    CygbuildEcho "== Strip command"

    find -L "$dir"              \
        -type f                 \
        '('                     \
            -name "*.exe"       \
            -o -name "*.dll"    \
            -o -name "*.a"      \
            -o -name "*.so"     \
        ')'                     \
        > $retval

    local file type

    [ -s $retval ] || return 0

    while read file
    do
        file $file > $retval.type
        [ -s $retval.type ] || continue

        type=$(< $retval.type)

        if [[ "$type" == *Intel* ]]; then
            CygbuildVerb "-- strip $file"
            strip "$file"

        else
            CygbuildVerb "-- [INFO] Not a binary executable;" \
                 " strip skipped for $file"
        fi

    done < $retval
}

function CygbuildStripCheck()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local dir="$instdir"

    find -L "$dir" \
        -type f '(' -name "*.exe" -o -name "*dll" ')' \
        | head --lines=1 \
        > $retval

    local file
    [ -s $retval ] && file=$(< $retval)

    if [ ! "$file" ]; then

        find $instdir -type f -name "*.a" -o -name "*.la" > $retval
        [ -s $retval ] && file=$(< $retval)

        if [ ! "$file" ]; then
            file=
            CygbuildVerb \
                "-- [NOTE] No *.exe, *.a or *.dll files, skipped strip."
            return 0
        fi

        CygbuildVerb "-- Hm, looks like a library .a or .la package," \
                 "skipping strip."
        return 0
    fi

    #   If strip has been run, then 'nm file.exe':
    #       nm: file.exe: no symbols
    #
    #   Sometimes it says:
    #       Not an x86 executable

    local saved="$IFS"
    local IFS=" "
        nm $file 2>&1 | head --lines=1 > $retval
        set -- $(< $retval)
    IFS="$saved"

    if [[ "$*" == *no*symbols* ]]; then
        return 0

    elif [[ "$*"  == *Not*x86* ]]; then
        CygbuildEcho "-- [ERROR] $file is not valid executable"
        file $file
        return 0

    else
        CygbuildVerbWarn "-- [WARN] Symbols found." \
                         "I'm going to call [strip]"
        CygbuildCmdStripMain
    fi
}

function CygbuildCmdFilesWrite()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local todir="$1"                                            # destdir
    shift
    local trydirs="$*"

    if [[ ! (-d $1 || -d $2) ]]; then
        CygbuildWarn "$id: [ERROR] Template directory does not exist: [$from1]"
        CygbuildWarn "$id: it should be at /etc/cygbuild/template if you" \
             "installed cygbuild package. See Web page for download."
        return 1
    fi

    if [ ! -d "$todir" ]; then
        CygbuildWarn "$id: [ERROR] Write directory does not exist: $todir"
        return 1
    fi

    CygbuildEcho "-- Writing default files to" ${todir#$srcdir/}

    local file

    for file in package.README setup.hint
    do
        CygbuildFileExists "$file" $trydirs > $retval || return $?
        local from=$(< $retval)
        local dest="$todir/$file"

        [[ $file == *README ]] && dest="$todir/$PKG.README"

        if [ -f "$dest" ]; then
            CygbuildVerb "-- Skip, already exists $dest"
        else
            cp $verbose "$from" "$dest" || return $?
        fi
    done

    local unpack="*@(cygwin-announce.mail.ex)"                 # remove *.tmp
    local dir

    for dir in $trydirs
    do
        [ ! -d "$dir" ] && continue

        for file in $dir/*.ex
        do
            [ ! -f "$file" ] && continue

            local name=${file##*/}      # /path/to/file.sh.tmp => file.sh.tmp
            local plain=${name%.ex}     # file.sh.ex => file.sh
            local dest="$todir/$plain"

            if [ -f "$dest" ]; then
                #   User has taken template file into use
                CygbuildVerb "-- Skip, already exists $dest"

            elif [ -f "$todir/$name" ]; then
                #  Template file is already there.
                :
            else
                cp $verbose "$file" "$todir" || return $?

                if [[ "$name" == $unpack ]] && [ ! -f "$dest" ]; then
                    mv "$todir/$name" "$dest" || return $?
                fi
            fi
        done
    done
}

function CygbuildCmdFileUpdateConfigs()
{
    local id="$0.$FUNCNAME"

    local destdir="$DIR_CYGPATCH"

    [ -d "$destdir" ] || return 0

    [ -f "$destdir/config.guess" ] || return 0

    CygbuildEcho "-- [NOTE] Updating latest config.{guess,sub} files"

    CygbuildPushd
        cd "$destdir"
        ${test:+echo} rm -f config.sub config.guess
        CygbuildConfigGuessDownload
    CygbuildPopd
}

function CygbuildCmdFilesMain()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local templatedir="$CYGBUILD_TEMPLATE_DIR_MAIN"

    if [ ! "$templatedir" ] || [ ! -d "$templatedir" ]; then
        CygbuildWarn "$id [ERROR] Can access templatedir: '$templatedir'"
        return 1
    fi

    local destdir="$DIR_CYGPATCH"
    local userdir="$CYGBUILD_TEMPLATE_DIR_USER"

    if [ ! "$destdir" ]; then
        CygbuildWarn "$id [ERROR] variable 'destdir' is empty"
        return 1
    fi

    if [ ! -d "$destdir" ]; then
        CygbuildCmdMkdirs "$verbose" || return 1
    fi

    CygbuildCmdFilesWrite "$destdir" "$userdir" "$templatedir"
    CygbuildCmdFileUpdateConfigs
}

function CygbuildCmdPackageBinMain()
{
    local strip="$1"

    CygbuildNoticeMaybe
    CygbuildNoticeGPG
    CygbuildNoticeDevel "pacakge"

    if [ "$strip" ]; then
        CygbuildStripCheck      &&
        CygbuildCmdPkgBinaryMain
    else
        CygbuildCmdPkgBinaryMain
    fi
}

function CygbuildCmdPackageDevMain()
{
    local strip="$1"

    CygbuildNoticeMaybe

    if [ "$strip" ]; then
        CygbuildStripCheck      &&
        CygbuildCmdPkgDevelMain
    else
        CygbuildCmdPkgDevelMain
    fi
}

function CygbuildCmdAllMain()
{
    local id="$0.$FUNCNAME"
    local finish="$1"

    #   The "prep" will also run "clean" and "distclean"
    #   because there are misconfigured source packages
    #   that dstribute compiled binaries.

    CygbuildEcho "-- [NOTE] command [all] is used for checking" \
         "build procedure only." \
         "See -h for source development options."

    CygbuildCmdGPGVerifyMain Yn     &&
    CygbuildCmdPrepMain             &&
    CygbuildCmdShadowMain           &&
    CygbuildCmdConfMain             &&
    CygbuildCmdBuildMain            &&
    CygbuildCmdInstallMain          &&
    CygbuildCmdStripMain            &&

    if CygbuildWasLibraryInstall ; then
        CygbuildCmdPackageDevMain

    else
        CygbuildCmdPkgBinaryMain &&
        {
            if CygbuildHelpSourcePackage ; then
                CygbuildCmdPkgSourceMain
            elif [ "$OPTION_GBS_COMPAT" ] ; then
                CygbuildEcho "-- Not attempting to build a source package"
            fi ;
        }
    fi

    local status=$?

    if [ ! "$finish" ] ; then
        return $status
    fi

    if [ "$status" != "0" ]; then
        if CygbuildAskYes "There was an error. Run [finish]"
        then
            CygbuildCmdFinishMain
        else
            echo "... remove the SRC directory when ready"
        fi
    else
        CygbuildCmdFinishMain
    fi
}

function CygbuildCmdFinishMain()
{
    local id="$0.$FUNCNAME"
    local status=0

    if [[ $objdir == *$PKG-$VER*  ]];then

        CygbuildEcho "== finish: removing $objdir"

        if CygbuildIsGbsCompat ; then
            CygbuildEcho "-- [NOTE] GBS compat mode: results" \
                "are not in ./$sinstdir_relative" \
                 "but in $TOPDIR. Please note that possible GPG signatures" \
                 "are now invalid"

            CygbuildPushd
                #   Display *-src package and binary package
                cd "$TOPDIR" && ls --all -lt | head --lines=3 | sed 's/^/   /'
            CygbuildPopd
        fi

        if [ "$(pwd)" = "$objdir" ]; then
            cd "$TOPDIR"                 #  Can't remove, if we're inside it
        fi

        rm -rf "$objdir"
        status=$?

        if [ -d "$objdir" ]; then
            CygbuildEcho "-- [NOTE] rm failed. Is Windows using the directory?"
        fi

    else
        CygbuildWarn "$id: [WARN] Doesn't look like unpack dir [$PKG-$VER]," \
             "so not touching $objdir"
    fi

    return $status
}

#######################################################################
#
#       Guess functions: so that -f or -r need not be supplied
#
#######################################################################

function CygbuildFilePackageGuessFromDirectory()
{
    local id="$0.$FUNCNAME"
    local dir=$(pwd)
    local ret

    #   Does it look like it would have foo-N.N ?

    [[ ! $dir == *[0-9]* ]]  && return 1

    if CygbuildDefineVersionVariables $dir ; then

        ret="$CYGBUILD_STATIC_VER_PACKAGE-$CYGBUILD_STATIC_VER_VERSION"

        #  Directory looks like package-N.N/ add RELEASE

        if [ "$OPTION_RELEASE" ]; then
            ret="$ret-$OPTION_RELEASE"
        fi
    fi

    dummy="$id: RETURN"         # Will show up in debugger
    echo $ret
}

function CygbuildFilePackageGuessArchive()
{
    local regexp="$1"
    local ignore="$2"

    ls | awk  \
    '
     $0 ~ regexp  {
        if (length(ignore)>1  &&  match($0, ignore) > 1)
        {
            next;
        }
        print;
    }' regexp="$regexp" ignore="$ignore"
}

function CygbuildFilePackageGuessMain()
{
    #   DESCRIPTION
    #
    #       1) This function searches *current* directory for Cygwin Net
    #       release source file (*.tar.xz). It is assumed, that this
    #       script (cygbuild) came from there and is used for building
    #       binaries from sources.
    #
    #       2) If user is instead trying to *port* a new package, he has
    #       ascended to the subdirectory foo-1.1/ where the packaging
    #       happens. In that case, the package name and version is read
    #       from the directory name.
    #
    #   LIST OF RETURN VALUES
    #
    #       <original package location>     This can be "!" if not found
    #       <release>
    #       <unpack dir i.e. TOP dir>

    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #   If there is only one PACKAGE in current directory, make an educated
    #   guess and use that if user did not supply option -f
    #   We expect to see files like:
    #
    #       package-N.N.tar.xz
    #       package-N.N.tar.gz
    #
    #   Finally, if there is a separate script that gets sources from external
    #   source, run it.

    local ret dummy len
    local -a arr

    #   The SRC package is not looked for, because that would be the Cygwin
    #   Net release source package. We need to find out the original
    #   developer package.

    if CygbuildIsArchiveScript ; then

        #  Debian uses: package_version.orig.tar.gz

        local nameRe
        CygbuildStrToRegexpSafe "$SCRIPT_PACKAGE" > $retval
        [ -s $retval ] && nameRe=$(< $retval)

        local verRe
        CygbuildStrToRegexpSafe "$SCRIPT_VERSION" > $retval
        [ -s $retval ] && verRe=$(< $retval)

        local ver="$nameRe[_-]$verRe"
        local ext="(orig[.])?tar[.](gz|bz2|lzma|xz)|tgz|tbz"

        CygbuildFilePackageGuessArchive \
          "$ver[.]($ext)" \
          "(-src.tar.(bz2|lzma|xz)|$nameRe-$verRe-$SCRIPT_RELEASE[.]|[.]sig)" \
          >  $retval

        arr=( $(< $retval) )
        dummy="${arr[*]}"          # For bash debugging, what we got?
        len=${#arr[*]}

        if [ $len = "0" ]; then
            CygbuildWarn "-- [WARN] Original archive detection failed."
        fi

    else

        CygbuildFilePackageGuessArchive \
            "[0-9.]+-[0-9].*(tar.bz2)" \
            >  $retval

        if [ ! -s $retval ]; then
            CygbuildFilePackageGuessArchive \
                "[0-9.]+-[0-9].*(tar.xz)" \
                >  $retval
        fi

        arr=( $(< $retval) )
        len=${#arr[*]}
    fi

    #   Check if all files have same first word: PACKAGENAME. If not,
    #   we do not know what package user wants to use

    if [[ $len -gt 1 ]]; then

        local tmp=${arr[0]}     # package-N.N.tar.gz
        local word=${tmp%%-*}   # package
        local element fail

        for element in ${arr[*]}
        do
            if [[ "$element" != $word* ]]; then
                CygbuildWarn \
                    "-- [WARN] Different archive files: $word <> $element" \
                    "Please use option -f FILE"
                fail=1
                break
            fi
        done

        if [ ! "$fail" ]; then
            ret=${arr[0]}
        fi

    elif [ "$len" = "1" ]; then     # Fresh and empty dir. Good. One tar file.

        ret=${arr[0]}

    else

        #  No tar files around to guess, try if this directory holds
        #  package name and user is currently porting a package

        CygbuildFilePackageGuessFromDirectory > $retval &&
        [ -s $retval ] && ret=$(< $retval)
    fi

    local pwd=$(pwd)

    if [[ "$ret"  &&  $ret != */*  ]]; then
        #  Make absolute path
        ret="$pwd/$ret"
    fi

    #   When doing Source builds, the script is named foo-2.1-1.sh
    #   and files are located in current directory. The Source directory
    #   is supposed be directly under it.

    local tdir release

    if [ "$SCRIPT_PKGVER" ]; then
        tdir="$pwd/$SCRIPT_PKGVER"
        release="$SCRIPT_RELEASE"
    fi

    dummy="$id: RETURN $ret $release $tdir"

    [ ! "$ret" ] && ret="!"         #  Nothing found

    echo "$ret" "$release" "$tdir"
}

function CygbuildFileReleaseGuess()
{
    local id="$0.$FUNCNAME"
    local retval="$CYGBUILD_RETVAL.$FUNCNAME"
    local ret

    #   Debian source packages are in format
    #   package_N.N.orig.tar.gz

    local -a arr

    ls 2> /dev/null \
        | $EGREP '[-_][0-9]+(-src\.tar|\.orig\.tar|\.patch)' \
        > $retval

    [ -s $retval ] && arr=( $(< $retval) )

    local dummy="$arr"          # For debug

    local count=${#arr[*]}

    if [ "$count" = "1" ]; then
        ret=${arr[0]}
    elif [ "$count" = "2" ]; then

        #  Found exactly two, source and binary package. Pick source
        #  package-N.N-RELEASE-src.tar.xz
        #  package-N.N-RELEASE.tar.xz

        echo "${arr[*]}"                      \
             | tr ' ' '\n'                   \
             | $EGREP --regexp='\.orig.|-src' \
             > $retval

        ret=$(< $retval)
    fi

    if [ "$ret" ]; then
        echo $ret
    else
        return 1
    fi
}

#######################################################################
#
#       Main
#
#######################################################################

function CygbuildProgramVersion()
{
    local exitcode="$1"
    shift
    local short="$2"
    shift

    local str

    if [ "$short" ]; then
        str="$CYGBUILD_NAME "
    fi

    str="$str$CYGBUILD_VERSION $CYGBUILD_HOMEPAGE_URL"

    if [ ! "$short" ]; then
        str="$str (C) $CYGBUILD_AUTHOR"
        str="$str, License: $CYGBUILD_LICENSE"
    fi

    local tag="##"

    if [ "$exitcode" ] ; then
        echo "$str"
        exit $exitcode
    else
        if [[ "$*" == *@( -C|--color)* ]]; then
            echo -e "$CYGBUILD_COLOR_BLACK1$tag $str$CYGBUILD_COLOR_RESET"
        else
            echo "$tag $str"
        fi
    fi
}

function CygbuildCommandMainCheckSpecial()
{
    local tmp

    if [[ "$*" == *--color* ]]; then
        OPTION_COLOR="color"                                    # global-def
    fi

    for tmp in "$@"
    do
        case "$tmp" in
            -h|help)
                CygbuildHelpShort 0
                ;;
            --help)
                CygbuildHelpLong 0
                ;;
            -V|--Version|--version)
                CygbuildProgramVersion 0
                ;;
            patch-list|plist|lspatch|ls-patch)
                DIR_CYGPATCH=CYGWIN-PATCHES
                CygbuildPatchFileList CYGWIN-PATCHES
                exit 0
                ;;
            download|dl|fetch)
                CygbuildCmdDownloadUpstream "$@"
                exit 0
                ;;
        esac
    done

    local opta="(-a|--arch)"
    local optb="(-b|--binary)"
    local optd="(-d|--dir)"
    local optc="(-c|--clean)"
    local opts
    opts="( +$opta +)?( +$optb)?( +$optc +)?( +$optd +)?"
    opts="$opts|( +$opta +)?( +$optc +)?( +$optb)?( +$optd +)?"
    opts="$opts|( +$opta +)?( +$optb +)?( +$optd)?( +$optc +)?"
    opts="$opts|( +$opta +)?( +$optd +)?( +$optc)?( +$optb +)?"

    local cmd=$(
        echo $* |
        grep --extended-regexp --only-matching --ignore-case \
             "cygsrc($opts| +)[a-z][^ ]+"
    )

    if [ "$cmd" ]; then

        set -- $cmd
        shift

        local mode="source-binary"
        local mkdir clean

        while :
        do
            case "$1" in
                -a|--arch)
                    arch="$2"
                    if [[ ! "$arch" == x86* ]]; then
                        CygbuildExit 1 "Incorrect --arch {x86, x86_64}: $arch"
                    fi
                    shift 2
                    ;;
                -b|--binary)
                    shift
                    mode="binary"
                    ;;
                -c|--clean)
                    shift
                    clean="clean"
                    ;;
                -d|--dir*)
                    shift
                    mkdir="mkdir"
                    ;;
                *)
                    break
                    ;;
            esac
        done

        local pkg

        for pkg in "$@"
        do
          CygbuildPushd

            if [ "$mkdir" ] && [ -e "$pkg" ]; then
                CygbuildDie "-- [ERROR] Already exists dir or file: $pkg"
            elif [ "$mkdir" ]; then
                mkdir "$pkg"    || exit $?
                cd "$pkg"       || exit $?
            fi

            local rmdir=""

            if ! CygbuildCmdDownloadCygwinPackage \
                   "$pkg" "$mode" "$clean" "$arch"
            then
                rmdir="rmdir"
            fi

          CygbuildPopd

          if [ "$rmdir" ] &&
             [ "$mkdir" ] &&
             CygbuildIsDirEmpty "$pkg"
          then
              rmdir "$pkg"
          fi

        done

        exit $?
    fi
}

function CygbuildCommandMain()
{
    local id="$0.$FUNCNAME"

    CygbuildProgramVersion '' 'short' "$*"
    CygbuildDefineGlobalScript
    CygbuildBootVariablesGlobalEtcMain

    CygbuildIsGbsCompat || CygbuildBootVariablesGlobalShareMain

    CygbuildBootVariablesGlobalMain

    local retval="$CYGBUILD_RETVAL.$FUNCNAME"

    #  If the first argument is filename, remove it
    #  ./links-1.99.20-1.sh --verbose all

    if [[ "$1" == *@(cygbuild|.sh) ]]; then
        shift
    fi

    CygbuildDefileInstallVariables

    # ................................................. read options ...
    #   Globally visible options

    unset OPTION_COLOR              # global-def
    unset OPTION_DEBUG              # global-def
    unset OPTION_DEBUG_VERIFY       # global-def
    unset OPTION_FILE               # global-def
    unset OPTION_FORCE              # global-def
    unset OPTION_GBS_COMPAT         # global-def
    unset OPTION_PASSPHRASE         # global-def
    unset OPTION_PREFIX_MODE        # global-def
    unset OPTION_PREFIX_CYGBUILD    # global-def
    unset OPTION_PREFIX_CYGINST     # global-def
    unset OPTION_PREFIX_CYGSINST    # global-def
    unset OPTION_PREFIX_MAN         # global-def
    unset OPTION_RELEASE            # global-def
    unset OPTION_SIGN               # global-def
    unset OPTION_VC_PACKAGE         # global-def FIXME: unused
    unset verbose                   # global-def
    unset test                      # global-def

    OPTION_SPACE="yes"              # global-def
    OPTION_COMPRESS="xz"            # global-def

    local arg args dir quiet release package
    local stripflag="yes"
    local OPTIND=1

    unset verbose

    #   On Cygwin upgrades, it may be possible that this proram is not
    #   installed

    local isgetopt="isgetop"

    if ! CygbuildWhich getopt > /dev/null ; then
        isgetopt=""

        CygbuildIsGbsCompat ||
        CygbuildDie "$id: [FATAL] 'getopt' (from package util-linux)" \
            "not in PATH. Cannot parse options."
    fi

    if [ "$isgetopt" ]; then
        getopt \
        -n $id \
        --long bzip2,color,cyginstdir:,cygbuilddir:,debug:,Debug:,email:,file:,force,gbs,init-pkgdb:,install-prefix:,install-prefix-man:,install-usrlocal,lzma,no-strip,passphrase,Prefix:,release:,sign:,test,verbose,xz \
        --option bcDd:e:f:glp:Pr:s:tvVx -- "$@" \
        > $retval

        [ "$?" = "0" ] || CygbuildDie "$id: Cannot read options."

        eval set -- $(< $retval)
    fi

    local tmp=15                        # safeguard against infinite loop

    while [ "$*" ]
    do
        local dummy="$1 => $*"                  # just for debugging
        tmp=$((tmp - 1))

        if [ $tmp -eq 0 ]; then
            CygbuildDie "$id:  [FATAL] Infinite loop while parsing arguments"
        fi

        case $1 in

            -b|--bzip2)
                OPTION_COMPRESS="bz2"           # global-def
                shift 1
                ;;

            -c|--color)
                OPTION_COLOR="color"            # global-def
                shift 1
                ;;

            --cyginstdir)
                OPTION_PREFIX_CYGINST="${2%/}"  # global-def no trail. slash
                shift 2
                ;;

            --cygbuilddir)
                OPTION_PREFIX_CYGBUILD="$2"     # global-def
                shift 2
                ;;

            --cygsinstdir)
                OPTION_PREFIX_CYGSINST="$2"     # global-def
                shift 2
                ;;

            -d|--debug)
                shift
                if [[ "$1" != [0-9] ]]; then
                    CygbuildDie "-- [ERROR] Debug level not numeric [$1]."
                else
                    OPTION_DEBUG=$1             # global-def
                    shift
                fi
                ;;

            -D|--Debug)
                OPTION_DEBUG_VERIFY="yes"       # global-def
                trap 1 2 3 15                   # cancel signals
                shift
                ;;

            -e|--email)
                export CYGBUILD_EMAIL="$2"      # global-def
                shift 2
                ;;

            -g|--gbs)
                export OPTION_GBS_COMPAT="gbs"  # global-def
                shift 1
                ;;

            -f|--file)
                OPTION_FILE="$2"                # global-def
                package="$2"
                CygbuildStrRemoveExt "$package" > $retval
                package=$(< $retval)
                shift 2
                ;;

            -F|--force)
                OPTION_FORCE="force"             # global-def
                shift 1
                ;;

            --install-prefix)
                OPTION_PREFIX_MODE="$2"              # global-def
                shift 2
                ;;

            --install-prefix-man)
                OPTION_PREFIX_MAN="$2"          # global-def
                shift 2
                ;;

            --install-usrlocal)
                shift
                CygbuildDefileInstallVariablesUSRLOCAL
                ;;

            -l|--lzma)
                OPTION_COMPRESS="lzma"          # global-def
                shift
                ;;

            -p|--passphrase)
                if [[ "$2" == -* ]]; then
                    CygbuildDie "$id: [ERROR] -p option needs pass phrase." \
                           "Got [$2]"
                fi

                OPTION_PASSPHRASE="$2"          # global-def
                shift 2
                ;;

            -r|--release)
                if [ "$2" = "date" ]; then
                    CygbuildDate > $retval
                    release=$(< $retval)
                else
                    release="$2"
                fi

                if ! CygbuildIsNumber "$release" ; then
                    CygbuildDie "$id: [FATAL] release value must be numeric." \
                         "Got [$release]"
                    exit 1
                fi

                OPTION_RELEASE=$release         # global-def
                shift 2
                ;;

            -s|--sign)
                if ! CygbuildGPGavailableCheck ; then
                    CygbuildWarn "-- [WARN] -s option used, but no gpg" \
                        "is available"
                fi

                if [[ "$2" == -* ]]; then
                    CygbuildDie "$id: [ERROR] -s option needs signer ID." \
                        "Got [$2]"
                fi

                OPTION_SIGN="$2"                # global-def
                shift 2
                ;;

            -t|--test)
                CygbuildEcho "-- [NOTE] RUNNING IN TEST MODE." \
                             "Changes are minimized"
                test="test"                     # global-def
                shift
                ;;

            -v|--verbose)
                verbose="--verbose"             # global-def
                shift
                ;;

            -x|--no-strip)
                stripflag=
                shift
                ;;

            --xz)
                OPTION_COMPRESS="xz"            # global-def
                shift
                ;;

            --) shift
                break
                ;;

            -*) CygbuildDie "$id: Unknown option  [$1]. Aborted."
                ;;

            [a-z]*)
                #  End of options, when getopt is not available
                # to write "--" marker
                set -- $*
                break
                ;;

        esac
    done

    # ........................................ determine environment ...

    if [ "$verbose" ] && [ ! "$OPTION_VC_PACKAGE" ]; then

        local vctype
        CygbuildVersionControlType > $retval
        [ -s $retval ] && vctype=$(< $retval)

        if [ "$vctype" ]; then
            CygbuildWarn \
                "-- [INFO] Version controlled source. Need option --checkout?"
        fi
    fi

    CygbuildCheckRunDir

    #  See if user supplied the RELEASE. This can be implicit in the
    #  package name, in which case it is ok. Otherwise user has to
    #  explicitly give it. Either way, we need to know it, otherwise
    #  the build directories cannot be determined correctly

    PACKAGE_NAME_GUESS=                 # global-def
    local releaseGuess srcGuess

    if [ ! "$package" ]; then

        if ! CygbuildFilePackageGuessMain > $retval ; then
            echo "$id: [FATAL] $? CygbuildFilePackageGuessMain"     \
                 " call error $?"                                   \
                 "Please debug and check content of $retval"        \
                 "Is filesystem full?"
            exit 1
        fi

        local -a arr=( $(< $retval) )

        PACKAGE_NAME_GUESS="${arr[0]}"
        releaseGuess="${arr[1]}"
        srcGuess="${arr[2]}"
        package="$PACKAGE_NAME_GUESS"

        if [ "$package" = "!" ]; then
            CygbuildDie "[FATAL] Can't determine package, version, release." \
                "Are you at dir foo-N.N/?"
        fi

    fi

    if [ ! "$release" ]; then           # User did not give -r RELEASE
        if [ "$releaseGuess" ]; then
            release="$releaseGuess"
        else
            CygbuildFileReleaseGuess > $retval
            [ -s $retval ] && release=$(< $retval)
        fi
    fi

    if [ ! "$release" ] && [ "$package" ]; then
        CygbuildStrRelease $package > $retval || exit 1
        tmprel=$(< $retval)
    fi

    if [ ! "$release" ] && [ ! "$tmprel" ]; then

        #   User did not supply -r, or we cannot parse release from
        #   -f NAME

        CygbuildVerb "-- [NOTE] -r RELEASE was not set. Assuming 1"
        release=1
    fi

    if [ $# -lt 1 ]; then
        CygbuildWarn "$id: [ERROR] COMMAND is missing." \
            "See option -h"
        exit 1
    fi

    # ................................................ set variables ...

    local top src argDirective

    if [ "$srcGuess" ]; then
        #   This is foo-2.1-1.sh unpack script, so source is not unpackges
        #   yet.
        top="$(pwd)"
        src="$srcGuess"
        argDirective=noCheckSrc
    else
        CygbuildSrcDirLocation $(pwd) > $retval
        local -a arr=( $(< $retval) )

        top=${arr[0]}
        src=${arr[1]}
    fi

    CygbuildDefineEnvClear

    CygbuildDefineGlobalMain    \
        "$top"                  \
        "$src"                  \
        "$release"              \
        "$package"              \
        "$argDirective"

    if [ $? -ne 0 ]; then
        #   Somehing went wrong while defining variables
        exit 1
    fi

    CygbuildIsGbsCompat || CygbuildReadmeReleaseMatchCheck

    # ................................................ user commands ...

    local status=0
    local opt

    for opt in "$@"
    do
        case $opt in
            all)
                CygbuildCmdAllMain finish
                status=$?
                ;;

            almostall)
                CygbuildCmdAllMain
                status=$?
                ;;

            auto*)
                CygbuildCmdAutotool
                status=$?
                ;;

            *clean)
                CygbuildCmdCleanByType $opt
                status=$?
                ;;

            check)
                CygbuildCmdInstallCheckMain
                status=$?
                ;;

            checksig)
                CygbuildCmdGPGVerifyMain
                status=$?
                ;;

            check-deps)
                # CygbuildCmdDependCheckMain
                CygbuildCmdInstallCheckBinFiles
                status=$?
                ;;

            conf*)
                CygbuildCmdConfMain
                status=$?
                ;;

            depend*|deps)
                CygbuildCmdDependMain
                status=$?
                ;;

            finish)
                CygbuildCmdFinishMain
                status=$?
                ;;

            files)
                CygbuildCmdFilesMain
                status=$?
                ;;

            install)
                CygbuildCmdInstallMain
                status=$?
                ;;

            install-extra)
                #  Generate POD manuals and
                #  compress manual pages etc.
                CygbuildInstallExtraMain
                status=$?
                ;;

            make|build)
                CygbuildCmdBuildMain
                status=$?
                ;;

            makedir*|mkdir*|dir*)
                CygbuildCmdMkdirs $verbose
                status=$?
                ;;

            makepatch|mkpatch)
                CygbuildCmdMkpatchMain   \
                    "$OPTION_SIGN"       \
                    "$OPTION_PASSPHRASE" &&
                CygbuildPatchCheck
                status=$?
                ;;

            package|bin-package|package-bin|pkg)
                CygbuildCmdPackageBinMain "$stripflag"
                status=$?
                ;;

            package-devel|pkgdev)
                CygbuildCmdPackageDevMain "$stripflag"
                status=$?
                ;;

            package-sign|pkg-sign|sign|sign-package)
                if CygbuildWasLibraryInstall ; then
                    CygbuildWarn "-- [WARN] Libs found." \
                        "Did you mean [package-devel]?"
                fi


                if [ ! "$OPTION_SIGN" ]; then
                    CygbuildWarn "[ERROR] -s option missing"
                    status=1
                else
                    CygbuildGPGsignMain      \
                        "$OPTION_SIGN"       \
                        "$OPTION_PASSPHRASE"
                    status=$?
                fi
                ;;

            patch)
                CygbuildPatchApplyMaybe
                status=$?
                ;;

            patch-check|pchk)
                verbose="--verbose" CygbuildPatchCheck
                CygbuildPatchListDisplay
                status=$?
                ;;

            prep*|unpack)
                CygbuildCmdPrepMain
                status=$?
                ;;

            preremove)
                CygbuildCmdPreremoveInstallMain
                status=$?
                ;;

            postinstall)
                CygbuildCmdPostInstallMain
                status=$?
                ;;

            publish)
                CygbuildCmdPublishMain
                status=$?
                ;;

            source-package|package-source|spkg)
                CygbuildHelpSourcePackage
                status=$?

                if [ "$status" = "0" ]; then
                    CygbuildNoticeGPG
                    CygbuildNoticeMaybe
                    CygbuildCmdPkgSourceMain
                    status=$?
                fi
                ;;

            readmefix)
                CygbuildCmdReadmeFixMain
                status=$?
                ;;

            rmshadow)
                CygbuildCmdShadowDelete
                status=$?
                ;;

            shadow)
                CygbuildCmdShadowDelete  &&
                CygbuildCmdMkdirs $verbose &&
                CygbuildCmdShadowMain
                status=$?
                ;;

            strip)
                if [ "$stripflag" ]; then
                    CygbuildCmdStripMain
                    status=$?
                else
                    status=0
                fi
                ;;

            test)
                CygbuildCmdTestMain
                status=$?
                ;;

            unpatch)
                CygbuildPatchApplyMaybe unpatch
                status=$?
                ;;

            vars)
                set -x
                CygbuildDefineGlobalMain "$TOPDIR" "$srcdir" \
                    "$release" "$package"
                return
                ;;

            verify)
                CygbuildCmdGPGVerifyMain
                status=$?
                ;;

            *)  CygbuildWarn "$id: [ERROR] bad argument [$opt]. See -h"
                exit 1
                ;;
        esac

        if [ "$status" != "0" ]; then
            CygbuildExit $status "$id: [FATAL] status is $status."
        fi
    done

    CygbuildEcho "-- Done."
}

function CygbuildMain()
{
    local id="$0.$FUNCNAME"

    #  Run a quick option check before we call all initialization
    #  function that are slow. Also export library functions.

    CygbuildBootVariablesId
    CygbuildBootVariablesGlobalColors
    CygbuildBootVariablesGlobalCacheMain
    CygbuildDefineGlobalCommands

    CygbuildCommandMainCheckSpecial "$@"
    CygbuildBootVariablesCache

    CygbuildBootFunctionExport

    #   This file can be included as a bash library. Like this:
    #
    #       #!/bin/bash
    #       ... load library
    #       export CYGBUILD_LIB=1
    #       source $(/usr/bin/which cygbuild)
    #       ... call functions

    if [ "$CYGBUILD_LIB" ]; then

        CygbuildBootVariablesGlobalMain

    else
        if [[ $# -gt 0 ]]; then
            CygbuildCommandMain "$@"
            CygbuildFileCleanTemp
        else
            CygbuildWarn "$id: No options given. See -h"
        fi
    fi
}

# Nothing interesting. It's for the developer to test parts
# of the code by hand

function Test ()
{
    PKG=$(basename $(pwd) | sed 's/-.*//')
    DIR_CYGPATCH=CYGWIN-PATCHES
    CYGBUILD_RETVAL="/tmp/Cygbuild.tmp"
    PERL=perl

    CygbuildVersionInfo $1
    CygbuildStrPackage $1
}

function TestRegression ()
{
    Test odt2txt-0.3+git20070827-1-src.tar.bz2
    Test findbugs-1.3.0-rc1.tar.gz
    Test jove4.16.0.70
    Test cabber_0.4.0-test5.orig.tar.gz
    Test unace1.2n
    Test ctorrent_1.3.4-dnh3.2.orig.tar.gz
    Test annoyance-filter-R1.0d
    Test xterm-229
    Test remake-3.80+dbg-0.61.tar.gz
}

trap 'CygbuildFileCleanTemp; exit 0' 1 2 3 15
CygbuildMain "$@"

# End of file
