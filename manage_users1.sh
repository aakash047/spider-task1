#!/bin/bash

base_dir=$(pwd)
user_data_file="$base_dir/username.csv"
log_file="$base_dir/manage_users.log"

# Function to log messages with timestamps
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$log_file"
}

# Function to create a user
create_user() {
    local username="$1"
    local group="$2"
    local permission="$3"

    # Check if the user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User '$username' already exists, skipping user creation"
        echo "User '$username' already exists, skipping user creation"
        return
    fi

    # Create group if it doesn't exist
    if ! getent group "$group" > /dev/null; then
        groupadd "$group"
        if [[ $? -ne 0 ]]; then
            error_message="Error: Failed to create group '$group' for user '$username'"
            echo "$error_message"
            log_message "$error_message"
            return
        fi
    fi

    # Create user with home directory in $base_dir
    useradd -m -d "$base_dir/$username" -g "$group" "$username"
    if [[ $? -ne 0 ]]; then
        error_message="Error: Failed to create user '$username'"
        echo "$error_message"
        log_message "$error_message"
        return
    fi

    log_message "Created user '$username' with group '$group'"

    # Set permissions for user's home directory
    chmod "$permission" "$base_dir/$username"
    if [[ $? -ne 0 ]]; then
        error_message="Error: Failed to set permissions '$permission' for user '$username' home directory"
        echo "$error_message"
        log_message "$error_message"
        return
    fi

    log_message "Set permissions '$permission' for user '$username' home directory"

    # Create 'projects' directory and README.md file
    mkdir -p "$base_dir/$username/projects" &>/dev/null
    echo "Welcome, $username! Some intro message here." > "$base_dir/$username/projects/README.md"
    log_message "Created 'projects' directory and 'README.md' file for user '$username'"

    success_message="Successfully created user: $username (group: $group, permission: $permission)"
    echo "$success_message"
    log_message "$success_message"
}

# Function to delete a user and all traces
delete_user() {
    local username="$1"
    
    # Check if the user exists
    if id -u "$username" >/dev/null 2>&1; then
        userdel -r "$username"
        if [[ $? -eq 0 ]]; then
            log_message "Deleted user '$username' and removed home directory"
            echo "Successfully deleted user '$username' and removed home directory"
        else
            log_message "Failed to delete user '$username'"
            echo "Failed to delete user '$username'"
        fi
    else
        echo "User '$username' does not exist"
    fi
}

# Function to modify user permissions
modify_user() {
    local username="$1"
    local group="$2"
    local permission="$3"

    # Check if the user exists
    if id -u "$username" >/dev/null 2>&1; then
        usermod -g "$group" "$username"
        if [[ $? -ne 0 ]]; then
            error_message="Error: Failed to assign user '$username' to group '$group'"
            echo "$error_message"
            log_message "$error_message"
            return
        fi
        
        chmod "$permission" "$base_dir/$username"
        if [[ $? -ne 0 ]]; then
            error_message="Error: Failed to set permissions '$permission' for user '$username' home directory"
            echo "$error_message"
            log_message "$error_message"
            return
        fi

        log_message "Modified user '$username': group='$group', permission='$permission'"
        echo "Successfully modified user: $username (group: $group, permission: $permission)"
    else
        echo "User '$username' does not exist"
    fi
}

# Batch processing from CSV file
process_csv() {
    # Read the CSV file into an array
    mapfile -t user_data < "$user_data_file"

    # Iterate over the array
    for line in "${user_data[@]}"; do
        IFS=, read -r username group permission <<< "$line"

        if [[ -z "$username" ]]; then
            log_message "Skipping empty line in '$user_data_file'"
            continue
        fi

        create_user "$username" "$group" "$permission"
    done

    success_message="User creation and setup from CSV completed!"
    echo "$success_message"
    log_message "$success_message"
}

# Interactive mode
interactive_mode() {
    while true; do
        echo "Choose an option:"
        echo "1. Add User"
        echo "2. Delete User"
        echo "3. Modify User"
        echo "4. Exit"
        read -rp "Enter your choice [1-4]: " choice

        case $choice in
            1)
                read -rp "Enter username: " username
                read -rp "Enter group: " group
                read -rp "Enter permissions (e.g., 755): " permission
                create_user "$username" "$group" "$permission"
                ;;
            2)
                read -rp "Enter username: " username
                delete_user "$username"
                ;;
            3)
                read -rp "Enter username: " username
                read -rp "Enter new group: " group
                read -rp "Enter new permissions (e.g., 755): " permission
                modify_user "$username" "$group" "$permission"
                ;;
            4)
                echo "Exiting interactive mode."
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Main script logic
if [[ "$1" == "--interactive" ]]; then
    interactive_mode
else
    process_csv
fi
