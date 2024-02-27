#/bin/bash
session_base_name='session.service.ts'
new_token=`pbpaste | sed 's/id_token: //'`

# Check that past buffer contains something that looks a JWT token, fail if not
case ${new_token:0:3} in
  eyJ)
    ;;
  *)
    echo "Token is not encoded JSON! (starts with: '${new_token:0:15}...')"
    exit 3
    ;;
esac


# the session file can be in slightly different places, check around for it.
session_file=`find src/app -iname "$session_base_name"`
case $session_file in
  "")
    echo 1>&2 "? ${session_base_name} not found! Are you in the right cwd?"
    exit 5
    ;;
esac

date
echo session_file: $session_file
case ${#session_file[@]} in
  0)
    echo 1>&2 "?No $session_base_name file found"
    exit 1
    ;;

  1)
    echo "new token tail:       ${new_token: -10}"
    ;;

  *)
    echo 1>&2 "?More than one match for '$session_base_name' file found. ($session_file)"
    exit 2
    ;;

esac


# Create a new token-line
token_line=`sed  -n "/idToken:/s/.*/${new_token}/p" ${session_file}`
echo "new idToken tail:     ${token_line: -10}"

# Actually make the token replacement
# Note: sometimes the file has the token on a separate line from the `idToken:` tag
# so we concatenate the line following and substitute everything within the first single
# quote pair.
sed -i "" "/'testI[dD]Token'/s//'${new_token}'/; /eyJ/s/'eyJ.*'/'${new_token}'/" ${session_file}

# Sed won't fail if no substitution is made, so we explicitly check for the replacement
grep --silent "${new_token}" ${session_file} || {
  echo 1>&2 "? Stream edit failed: Token NOT replaced"
  exit 4
}

echo "Token Replaced"

