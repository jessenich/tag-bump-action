#!/bin/sh

set -o errexit -o nounset -o pipefail

NAT='0|[1-9][0-9]*'
ALPHANUM='[0-9]*[A-Za-z-][0-9A-Za-z-]*'
IDENT="$NAT|$ALPHANUM"
FIELD='[0-9A-Za-z-]+'

SEMVER_REGEX="\
^[vV]?\
($NAT)\\.($NAT)\\.($NAT)\
(\\-(${IDENT})(\\.(${IDENT}))*)?\
(\\+${FIELD}(\\.${FIELD})*)?$"

PROG=semver
PROG_VERSION="3.2.0"

USAGE="\
Usage:
  $PROG bump (major|minor|patch|release|prerel [<prerel>]|build <build>) <version>
  $PROG compare <version> <other_version>
  $PROG diff <version> <other_version>
  $PROG get (major|minor|patch|release|prerel|build) <version>
  $PROG --help
  $PROG --version

Arguments:
  <version>  A version must match the following regular expression:
             \"${SEMVER_REGEX}\"
             In English:
             -- The version must match X.Y.Z[-PRERELEASE][+BUILD]
                where X, Y and Z are non-negative integers.
             -- PRERELEASE is a dot separated sequence of non-negative integers and/or
                identifiers composed of alphanumeric characters and hyphens (with
                at least one non-digit). Numeric identifiers must not have leading
                zeros. A hyphen (\"-\") introduces this optional part.
             -- BUILD is a dot separated sequence of identifiers composed of alphanumeric
                characters and hyphens. A plus (\"+\") introduces this optional part.

  <other_version>  See <version> definition.

  <prerel>  A string as defined by PRERELEASE above. Or, it can be a PRERELEASE
            prototype string (or empty) followed by a dot.

  <build>   A string as defined by BUILD above.

Options:
  -v, --version          Print the version of this tool.
  -h, --help             Print this help message.

Commands:
  bump     Bump by one of major, minor, patch; zeroing or removing
           subsequent parts. \"bump prerel\" sets the PRERELEASE part and
           removes any BUILD part. A trailing dot in the <prerel> argument
            introduces an incrementing numeric field which is added or
           bumped. If no <prerel> argument is provided, an incrementing numeric
           field is introduced/bumped. \"bump build\" sets the BUILD part.
           \"bump release\" removes any PRERELEASE or BUILD parts.
           The bumped version is written to stdout.

  compare  Compare <version> with <other_version>, output to stdout the
           following values: -1 if <other_version> is newer, 0 if equal, 1 if
           older. The BUILD part is not used in comparisons.

  diff     Compare <version> with <other_version>, output to stdout the
           difference between two versions by the release type (MAJOR, MINOR,
           PATCH, PRERELEASE, BUILD).

  get      Extract given part of <version>, where part is one of major, minor,
           patch, prerel, build, or release.

See also:
  https://semver.org -- Semantic Versioning 2.0.0"

function error {
  echo -e "$1" >&2
  exit 1
}

function usage_help {
  error "$USAGE"
}

function usage_version {
  echo -e "${PROG}: $PROG_VERSION"
  exit 0
}

function validate_version {
  local version=$1
  if [[ "$version" =~ $SEMVER_REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      local prere=${BASH_REMATCH[4]}
      local build=${BASH_REMATCH[8]}
      eval "$2=(\"$major\" \"$minor\" \"$patch\" \"$prere\" \"$build\")"
    else
      error "version $version does not match the semver scheme 'X.Y.Z(-PRERELEASE)(+BUILD)'. See help for more information."
  fi
}

function is_nat {
    [[ "$1" =~ ^($NAT)$ ]]
}

function is_null {
    [ -z "$1" ]
}

function order_nat {
    [ "$1" -lt "$2" ] && { echo -1 ; return ; }
    [ "$1" -gt "$2" ] && { echo 1 ; return ; }
    echo 0
}

function order_string {
    [[ $1 < $2 ]] && { echo -1 ; return ; }
    [[ $1 > $2 ]] && { echo 1 ; return ; }
    echo 0
}

# given two (named) arrays containing NAT and/or ALPHANUM fields, compare them
# one by one according to semver 2.0.0 spec. Return -1, 0, 1 if left array ($1)
# is less-than, equal, or greater-than the right array ($2).  The longer array
# is considered greater-than the shorter if the shorter is a prefix of the longer.
#
function compare_fields {
    local l="$1[@]"
    local r="$2[@]"
    local leftfield=( "${!l}" )
    local rightfield=( "${!r}" )
    local left
    local right

    local i=$(( -1 ))
    local order=$(( 0 ))

    while true
    do
        [ $order -ne 0 ] && { echo $order ; return ; }

        : $(( i++ ))
        left="${leftfield[$i]}"
        right="${rightfield[$i]}"

        is_null "$left" && is_null "$right" && { echo 0  ; return ; }
        is_null "$left"                     && { echo -1 ; return ; }
                           is_null "$right" && { echo 1  ; return ; }

        is_nat "$left" &&  is_nat "$right" && { order=$(order_nat "$left" "$right") ; continue ; }
        is_nat "$left"                     && { echo -1 ; return ; }
                           is_nat "$right" && { echo 1  ; return ; }
                                              { order=$(order_string "$left" "$right") ; continue ; }
    done
}

# shellcheck disable=SC2206
