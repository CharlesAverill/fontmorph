TEXENGINE=pdflatex

FONTSIZE=300
PTSIZE=12
PRECISION=10

RAWCHARS=$(cat contents.txt)
CHARS=$(tr -d '[:space:]' < contents.txt | sed -e 's/\(.\)/\1/g')
N_CHARS=${#CHARS}

X_HEIGHT_MIN="186/36"
X_HEIGHT_MAX="64/10"
# Described in "The Concept of a Meta-Font" as e-height
BAR_HEIGHT_MIN="104.4/36"
BAR_HEIGHT_MAX="32/10"
DESC_DEPTH_MIN="84/36"
DESC_DEPTH_MAX="4"
LHAIR_MIN="9.5/36"
UHAIR_MIN="11.5/36"
LSTEM_MIN="28/36"
USTEM_MIN="35/36"
HAIR_STEM_MAX="1"
# Bulb diameter
FLARE_MIN="36/36"
FLARE_MAX="11/10"

OVERSHOOT_MIN="9/36"
OVERSHOOT_MAX="1/10"

function lerp { # lerp a b t
	echo "scale=${PRECISION}; $1 + ($2 - $1) * $3" | bc
}

number_to_string() {
  local num=$1
  local result=""

  while ((num >= 0)); do
    ((remainder = num % 26))
    result=$(printf \\$(printf '%03o' $((97 + remainder))))$result
    ((num = (num / 26) - 1))
  done

  echo "$result"
}

cd mf # https://www.ctan.org/tex-archive/fonts/cm/mf

FONT_DECLS=""

for (( i=0; i<${#CHARS}; i++ )); do
  cp "cmr${PTSIZE}.mf" temp.mf
  t=$(lerp 0 1 "1 - (${#CHARS}-$i)/${#CHARS}")
  echo $t

  # Do replacements
  sed -i "s%x_height#:=186/36pt#;%x_height#:=$(lerp $X_HEIGHT_MIN $X_HEIGHT_MAX $t)pt#;%g" temp.mf

  # Compile
  mf -halt-on-error '\mode=cx;' input temp.mf

  # Copy fonts out
  mv temp.tfm ../"font$i.tfm"
  gftopk "temp.${FONTSIZE}gf"
  mv "temp.${FONTSIZE}pk" ../"font$i.${FONTSIZE}pk"

  NUMLET=$(number_to_string $i)
  FONT_DECLS+="\newfont{\font$NUMLET}{out/font$i}"
done

cd ..

rm mf/temp*

# font declaration replacements
cp main.tex temp.tex
ESCAPED_REPLACE=$(printf '%s\n' "$FONT_DECLS" | sed -e 's/[\/&]/\\&/g')
sed -i "s#FONTDECLS#$ESCAPED_REPLACE#g" temp.tex

# content replacements
TO_INSERT=""
n="0"
for (( i=0; i < ${#RAWCHARS}; i++ )); do
  case ${RAWCHARS:$i:1} in 
    [[:space:]])
        TO_INSERT+="${RAWCHARS:$i:1}"
        continue
      ;;
  esac
  NUMLET=$(number_to_string $n)
  TO_INSERT+="\font$NUMLET{}${CHARS:$n:1}"
  
  n=$(echo "$n + 1" | bc);
done
ESCAPED_REPLACE=$(printf '%s\n' "$TO_INSERT" | sed -e 's/[\/&]/\\&/g')
sed -i "s#CONTENTS#$ESCAPED_REPLACE#g" temp.tex

cat temp.tex

$TEXENGINE temp.tex

# Cleanup
rm temp.tex
rm *300pk *.tfm
mv temp.pdf main.pdf
