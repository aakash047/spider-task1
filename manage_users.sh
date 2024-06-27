#!/bin/bash
base_dir=$(pwd)
echo $base_dir
user_data_file="$base_dir/username.csv"
log_file="$base_dir/manage_users.log"

# Function to log messages with timestamps
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$log_file"
}

# Read the CSV file into an array
mapfile -t user_data < "$user_data_file"

# Iterate over the array
for line in "${user_data[@]}"; do
    IFS=, read -r username group permission <<< "$line"

    if [[ -z "$username" ]]; then
        log_message "Skipping empty line in '$user_data_file'"
        continue
    fi

    # Check if the user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User '$username' already exists, skipping user creation"
        continue
    fi

    # Create user
    useradd -m -d "$base_dir/$username" -g john.doe "$username"
    if [[ $? -ne 0 ]]; then
        error_message="Error: Failed to create user '$username'"
        echo "$error_message"
        log_message "$error_message"
        continue
    fi

    # Create group if it doesn't exist
    if ! getent group "$group" > /dev/null; then
        groupadd "$group"
        if [[ $? -ne 0 ]]; then
            error_message="Error: Failed to create group '$group' for user '$username'"
            echo "$error_message"
            log_message "$error_message"
            continue
        fi
    fi

    # Assign user to specified group
    usermod -g "$group" "$username"
    if [[ $? -ne 0 ]]; then
        error_message="Error: Failed to assign user '$username' to group '$group'"
        echo "$error_message"
        log_message "$error_message"
        continue
    fi

    log_message "Assigned user '$username' to group '$group'"

    # Set permissions for user's home directory
    chmod "$permission" "$base_dir/$username"
    if [[ $? -ne 0 ]]; then
        error_message="Error: Failed to set permissions '$permission' for user '$username' home directory"
        echo "$error_message"
        log_message "$error_message"
        continue
    fi

    log_message "Set permissions '$permission' for user '$username' home directory"

    # Create 'projects' directory and README.md file
    mkdir -p "$base_dir/$username/projects" &>/dev/null
    echo "Welcome, $username! Some intro message here." > "$base_dir/$username/projects/README.md"
    log_message "Created 'projects' directory and 'README.md' file for user '$username'"

    success_message="Successfully created user: $username (group: $group, permission: $permission)"
    echo "$success_message"
    log_message "$success_message"
done

success_message="User creation and setup completed!"
echo "$success_message"
log_message "$success_message"
