set -euo pipefail #ai-generated

# ---AI- generated materials:------------------------

# $sc → field in column sc (in our script, Smoker).
# $wc → field in column wc (Weight).
# g=... and w=... assign them to easier-to-read local variables.
# ; is just a statement separator (like ; in C/Java/JS).

# /.../ → regex literal.
# ^ → beginning of string.
# $ → end of string.
# [...] → character class.
# \t → tab character.
# + → one or more occurrences.
#| → logical OR inside regex.
# ; → separate multiple commands on the same line.
# "" → empty string replacement (delete).
#--------------------------------------------------

# Ensure the data file exists #ai-generated
if [ ! -f "NCBirths2004.csv" ]; then
  echo "ERROR: NCBirths2004.csv not found in $(pwd)" >&2
  exit 1
fi

head -1 NCBirths2004.csv > headers.txt # Save the first line exactly as-is
WEIGHT_COL=6
ALCOHOL_COL=4
SMOKER_COL=8
smoker_yes_weights=$(awk -F',' -v wc="$WEIGHT_COL" -v sc="$SMOKER_COL" 'NR>1{
  g=$sc; w=$wc;
  gsub(/"/,"",g); gsub(/\r/,"",g); gsub(/^[ \t]+|[ \t]+$/,"",g);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  # tolower is used to handle case variations; match beginning "y" for Yes
  if (tolower(g) ~ /^y/ && w ~ /^[0-9]+(\.[0-9]+)?$/) print w
}' NCBirths2004.csv | sort -n)

## count safely (handle empty case) #ai generated
if [ -z "$smoker_yes_weights" ]; then
  n_yes=0
else
  n_yes=$(printf '%s\n' "$smoker_yes_weights" | wc -l)
fi

# compute median from sorted list
if [ "$n_yes" -eq 0 ]; then
  median_yes=""
elif [ $((n_yes % 2)) -eq 1 ]; then
  # odd -> middle element
  median_yes=$(printf '%s\n' "$smoker_yes_weights" | awk 'NR==int((NR=FNR)/FNR){} { } # noop' )
  # safer compute with array:
  median_yes=$(printf '%s\n' "$smoker_yes_weights" | awk ' { a[++n]=$1 } END { print a[int(n/2)+1] }')
else
  # even -> average of two middle elements
  median_yes=$(printf '%s\n' "$smoker_yes_weights" | awk ' { a[++n]=$1 } END { printf "%f", (a[n/2]+a[n/2+1])/2 }')
fi
printf "%s\n" "$median_yes" > smoker-yes-med.txt # save numeric-only value (one line)

#Repeat for [Smoker = No ]
smoker_no_weights=$(awk -F',' -v wc="$WEIGHT_COL" -v sc="$SMOKER_COL" 'NR>1{
  g=$sc; w=$wc;
  gsub(/"/,"",g); gsub(/\r/,"",g); gsub(/^[ \t]+|[ \t]+$/,"",g);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  if (tolower(g) ~ /^n/ && w ~ /^[0-9]+(\.[0-9]+)?$/) print w
}' NCBirths2004.csv | sort -n)

#
if [ -z "$smoker_no_weights" ]; then
  n_no=0
else
  n_no=$(printf '%s\n' "$smoker_no_weights" | wc -l)
fi

if [ "$n_no" -eq 0 ]; then
  median_no=""
elif [ $((n_no % 2)) -eq 1 ]; then
  median_no=$(printf '%s\n' "$smoker_no_weights" | awk ' { a[++n]=$1 } END { print a[int(n/2)+1] }')
else
  median_no=$(printf '%s\n' "$smoker_no_weights" | awk ' { a[++n]=$1 } END { printf "%f", (a[n/2]+a[n/2+1])/2 }')
fi

printf "%s\n" "$median_no" > smoker-no-med.txt

#display medians
echo "Median weight (Smoker=Yes): $median_yes"
echo "Median weight (Smoker=No):  $median_no"

#Average weight by Alcohol = Yes/No
avg_yes=$(awk -F',' -v ac="$ALCOHOL_COL" -v wc="$WEIGHT_COL" 'NR>1{
  a=$ac; w=$wc;
  gsub(/"/,"",a); gsub(/\r/,"",a); gsub(/^[ \t]+|[ \t]+$/,"",a);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  if (tolower(a) ~ /^y/ && w ~ /^[0-9]+(\.[0-9]+)?$/) { sum+=w; n++ }
} END {
  if (n>0) printf "%f", sum/n
}' NCBirths2004.csv)
printf "%s\n" "$avg_yes" > alcohol-yes-avg.txt

avg_no=$(awk -F',' -v ac="$ALCOHOL_COL" -v wc="$WEIGHT_COL" 'NR>1{
  a=$ac; w=$wc;
  gsub(/"/,"",a); gsub(/\r/,"",a); gsub(/^[ \t]+|[ \t]+$/,"",a);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  if (tolower(a) ~ /^n/ && w ~ /^[0-9]+(\.[0-9]+)?$/) { sum+=w; n++ }
} END {
  if (n>0) printf "%f", sum/n
}' NCBirths2004.csv)

printf "%s\n" "$avg_no" > alcohol-no-avg.txt

echo "Average weight (Alcohol=Yes): $avg_yes"
echo "Average weight (Alcohol=No):  $avg_no"

## Stddev for Alcohol = Yes (sample stddev, n-1 in denominator)
stddev_yes=$(awk -F',' -v ac="$ALCOHOL_COL" -v wc="$WEIGHT_COL" 'NR>1{
  a=$ac; w=$wc;
  gsub(/"/,"",a); gsub(/\r/,"",a); gsub(/^[ \t]+|[ \t]+$/,"",a);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  if (tolower(a) ~ /^y/ && w ~ /^[0-9]+(\.[0-9]+)?$/) { n++; sum+=w; sumsq+=w*w }
} END {
  if (n>1) {
    mean = sum / n;
    sd = sqrt((sumsq - n*mean*mean) / (n-1));  # sample stddev
    printf "%f", sd;
  } else if (n==1) {
    print 0;
  }
}' NCBirths2004.csv)

printf "%s\n" "$stddev_yes" > stddev-alcohol-yes.txt
echo "Stddev (Alcohol=Yes): $stddev_yes"


# Problem 3: Standard Deviation of Weight where Alcohol=Yes (single pass)
# AI-assisted: Using the computational formula for standard deviation
# Calculate sd using AWK in a single pass through the data; 
stddev_yes=$(awk -F',' -v ac="$ALCOHOL_COL" -v wc="$WEIGHT_COL" 'NR>1{
  a=$ac; w=$wc; 
  gsub(/"/,"",a); gsub(/\r/,"",a); gsub(/^[ \t]+|[ \t]+$/,"",a);
  gsub(/"/,"",w); gsub(/\r/,"",w); gsub(/^[ \t]+|[ \t]+$/,"",w);
  if (tolower(a) ~ /^y/ && w ~ /^[0-9]+(\.[0-9]+)?$/) { 
    n++; 
    sum += w; 
    sumsq += w*w 
  }
} END {
  if (n > 0) {
    mean = sum / n;
    variance = (sumsq - n*mean*mean) / n;  # population stddev (use n-1 for sample)
    printf "%.6f", sqrt(variance);
  } else {
    print "0";
  }
}' NCBirths2004.csv)

printf "%s\n" "$stddev_yes" > stddev-alcohol-yes.txt
echo "Standard Deviation (Alcohol=Yes): $stddev_yes"

# done -ai generated
exit 0
