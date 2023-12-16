#!/bin/bash

generate_filename() {
  local raw_input="$1"
  local formatted_title

  # Convert the input to lowercase
  formatted_title=$(echo "$raw_input" | tr '[:upper:]' '[:lower:]')

  # Replace spaces with dashes
  formatted_title=${formatted_title// /-}

  # Remove characters that are illegal in filenames
  formatted_title=${formatted_title//[^[:alnum:]-]/}

  echo "$(get_todays_date)-$formatted_title.md"
}

parse_bool() {
  local raw_input="$1"

  if [ "$has_tldr" = "y" ]; then
    echo "True"
  # elif [ "$has_tldr" = "n" ]; then
  #   echo false
  else
    # echo "Did not receive  \"y\" or \"n\", assuming \"n\""
    echo "False"
  fi
}

# Function to get today's date in yyyy-mm-dd format
get_todays_date() {
  date +"%Y-%m-%d"
}

go_to_project_root() {
  # Get the directory of the currently executing script
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  # Change the working directory to the parent directory of the script
  parent_dir=$(dirname "$script_dir")
  cd "$parent_dir" || exit 1  # Change directory or exit if it fails
}

replace_placeholder_field() {
  local string="$1"
  local field_name="$2"
  local field_value="$3"

  echo -e "$string" | sed -e "s|<%$field_name%>|$field_value|g"
}

# read_file_content() {
#   local file_path="$1"
#   local file_content=""

#   while IFS= read -r line; do
#       file_content="$file_content$line\n"
#   done < "$file_path"

#   echo -e "$file_content"  # Output the content with newlines preserved
# }

generate_post_contents() {
  local title="$1"
  local tags="$2"
  local tldr="$3"

  local content=$(cat ./scripts/templates/post.md)
  content=$(replace_placeholder_field "$content" "TITLE" "$title")
  content=$(replace_placeholder_field "$content" "TAGS" "$tags")
  content=$(replace_placeholder_field "$content" "TLDR" "$tldr")
  echo -e "$content"
}

generate_tldr_contents() {
  local title="$1"
  local tags="$2"
  local date="$3"

  local content=$(cat ./scripts/templates/tldr.md)
  content=$(replace_placeholder_field "$content" "TITLE" "$title")
  content=$(replace_placeholder_field "$content" "TAGS" "$tags")
  content=$(replace_placeholder_field "$content" "DATE" "$date")
  echo -e "$content"
}

echo "Enter the title of your post:"
read -r title

read -r -p "Enter space separated tags for your post (default none): " tags

read -n 1 -p "Does your post have a TLDR? [y/n]: " has_tldr
echo ""

filename=$(generate_filename "$title")
has_tldr=$(parse_bool "$has_tldr")

go_to_project_root

echo "Creating post at _posts/$filename"
post_contents=$(generate_post_contents "$title" "$tags" "$has_tldr")
echo -e "$post_contents" > "./_posts/$filename"

if [ "$has_tldr" = "True" ]; then
  echo "Creating tldr at tldr/$filename"
  current_date=$(get_todays_date)
  tldr_contents=$(generate_tldr_contents "$title" "$tags" "$current_date")
  echo -e "$tldr_contents" > "./tldr/$filename"
fi
