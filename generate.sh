cd mf # https://www.ctan.org/tex-archive/fonts/cm/mf

PTSIZE=12
PRECISION=10

CHARS=$(tr -d '[:space:]' < ../letter.txt | sed -e 's/\(.\)/\1/g')
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

for (( i=0; i<${#CHARS}; i++ )); do
  cp "cmr${PTSIZE}.mf" temp.mf
  t=$(lerp 0 1 "1 - (${#CHARS}-$i)/${#CHARS}")
  echo $t

  # Do replacements
  sed -i "s%x_height#:=186/36pt#;%x_height#:=$(lerp $X_HEIGHT_MIN $X_HEIGHT_MAX $t)pt#;%g" temp.mf

  mf -halt-on-error temp.mf
  mv temp.2602gf ../generated_fonts/"$i.2602gf"
  rm temp.mf
done

cd ..
