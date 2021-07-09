compute_badge_color() {
  local THRESHOLDS
  IFS=',' read -r -a THRESHOLDS <<< "$1"
  local COVERAGE_METRIC=$2
  # compute badge color from coverage-metric
    # Colors
      # brightgreen [100-90[
      # green [90-80[
      # yellowgreen [80-70[
      # yellow [70-60[
      # orange [60-50[
      # red [50-0]
  local BADGE_COLORS=(red orange yellow yellowgreen green brightgreen)
  local COLOR_INDEX=0
  for i in "${!THRESHOLDS[@]}"; do
    if (( $(echo "$COVERAGE_METRIC > ${THRESHOLDS[$i]}" | bc -l) )); then
      COLOR_INDEX=$((i+1))
    fi
  done
  local BADGE_COLOR=${BADGE_COLORS[$COLOR_INDEX]}
  echo "$BADGE_COLOR"
}

fetch_badge() {
  local PROJECT_NAME=$1
  local COVERAGE_METRIC=$2
  local BADGE_COLOR=$3
  local OUTPUT_FILE=$4
  local PROJECT_NAME_PARTS=(${PROJECT_NAME//-/ })
  local PASCAL_CASE_PROJECT_NAME
  PASCAL_CASE_PROJECT_NAME=$(printf %s "${PROJECT_NAME_PARTS[@]^}")
  curl \
    "https://img.shields.io/badge/Coverage%20$PASCAL_CASE_PROJECT_NAME-$COVERAGE_METRIC%25-$BADGE_COLOR" \
    -o "$OUTPUT_FILE" &> /dev/null
}