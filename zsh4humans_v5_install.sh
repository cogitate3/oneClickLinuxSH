#!/bin/sh
# 这种写法明确告诉 shell 使用完整的命令路径，而不依赖于 shell 的内置命令或别名
# 例如 'command' 'ls' 确保使用系统的 ls 命令，而不是可能被重定义的别名

# Check if the shell is Zsh by checking if the ZSH_VERSION variable is set
if '[' '-n' "${ZSH_VERSION-}" ']'; then  
  # If Zsh is used, emulate sh shell behavior and set strict error handling
  # This ensures that the script behaves similarly in both Zsh and sh shells
  'emulate' 'sh' '-o' 'err_exit' '-o' 'no_unset'
else
  # If not Zsh, set basic shell error handling flags
  # This sets the shell to exit on errors and unset variables
  'set' '-ue'
fi

# Determine the platform (operating system and architecture) of the system
platform="$('command' 'uname' '-sm')"
platform="$('printf' '%s' "$platform" | 'command' 'tr' '[A-Z]' '[a-z]')"

# Check if the platform is supported
case "$platform" in
  'darwin arm64');;  # Apple M1/M2 chips
  'darwin x86_64');;  # Intel-based Macs
  'linux aarch64');;  # Linux on ARM64 architecture
  'linux armv6l');;  # Linux on ARMv6 architecture
  'linux armv7l');;  # Linux on ARMv7 architecture
  'linux armv8l');;  # Linux on ARMv8 architecture
  'linux x86_64');;  # Linux on x86-64 architecture
  'linux i686');;  # Linux on i686 architecture
  *)
    # If the platform is not supported, print an error message and exit
    >&2 'printf' '\033[33mz4h\033[0m: sorry, unsupported platform: \033[31m%s\033[0m\n' "$platform"
    'exit' '1'
  ;;
esac

# Check if curl or wget is available for downloading files
if command -v 'curl' >'/dev/null' 2>&1; then
  fetch='command curl -fsSLo'
elif command -v 'wget' >'/dev/null' 2>&1; then
  fetch='command wget -O'
else
  # If neither curl nor wget is available, print an error message and exit
  >&2 'printf' '\033[33mz4h\033[0m: please install \033[32mcurl\033[0m or \033[32mwget\033[0m\n'
  'exit' '1'
fi

# Check if the HOME directory exists and is a directory
if '[' '!' '-d' "${HOME-}" ']'; then
  # If the HOME directory does not exist or is not a directory, print an error message and exit
  >&2 'printf' '\033[33mz4h\033[0m: \033[1m$HOME\033[0m is not a directory\n'
  'exit' '1'
fi

# Get the effective user ID
euid="$('command' 'id' '-u')"

# Check if the script is running with root privileges
if '[' "$euid" '=' '0' ']'; then
  # If running with root privileges, check the ownership of the HOME directory
  home_ls="$('command' 'ls' '-ld' '--' "$HOME")"
  home_owner="$('printf' '%s\n' "$home_ls" | 'command' 'awk' 'NR==1 {print $3}')"
  if '[' "$home_owner" '!=' 'root' ']'; then
    # If the HOME directory is not owned by root, print an error message and exit
    >&2 'printf' '\033[33mz4h\033[0m: please retry without \033[4;32msudo\033[0m\n'
    'exit' '1'
  fi
fi

# Check if the script is running in a terminal
if '[' '!' '-t' '0' ']'; then
  # If not running in a terminal, print an error message and exit
  >&2 'printf' '\033[33mz4h\033[0m: standard input is not a \033[1mTTY\033[0m\n'
  'exit' '1'
fi

if '[' '!' '-t' '1' ']'; then
  # If not running in a terminal, print an error message and exit
  >&2 'printf' '\033[33mz4h\033[0m: standard output is not a \033[1mTTY\033[0m\n'
  'exit' '1'
fi

if '[' '!' '-t' '2' ']'; then
  # If not running in a terminal, print an error message and exit
  >&2 'printf' '\033[33mz4h\033[0m: standard error is not a \033[1mTTY\033[0m\n'
  'exit' '1'
fi

# Save the current terminal settings
saved_tty_settings="$('command' 'stty' '-g')"

# Initialize variables for Zsh configuration files
zshenv=''
zshrc=''
z4h=''

# Define a cleanup function to restore terminal settings and remove temporary files
cleanup() {
  'trap' '-' 'INT' 'TERM' 'EXIT'
  'command' 'rm' '-f' '--' "$zshenv" "$zshrc" "${zshrc:+$zshrc.bak}" "$z4h"
  'command' 'stty' "$saved_tty_settings"
}

# Set up the cleanup function to run on exit
'trap' 'cleanup' 'INT' 'TERM' 'EXIT'

# Define a function to read a single character from the user
read_choice() {
  choice=''
  'command' 'stty' '-icanon' 'min' '1' 'time' '0'
  while :; do
    c="$('command' 'dd' 'bs=1' 'count=1' 2>'/dev/null' && 'echo' 'x')"
    choice="$choice${c%x}"
    n="$('printf' '%s' "$choice" | 'command' 'wc' '-m')"
    '[' "$n" '-eq' '0' ']' || 'break'
  done
  'command' 'stty' "$saved_tty_settings"
  '[' "$choice" '=' "$lf" ] || 'echo'
}

# Print a greeting message
>&2 'printf' 'Greetings, Human!\n'
>&2 'printf' '\n'
>&2 'printf' 'What kind of \033[1mkeyboard\033[0m are you using?\n'
>&2 'printf' '\n'
>&2 'printf' '  \033[1m(1)\033[0m  Mac. It has \033[32mOption\033[0m key(s) and does not have \033[33mAlt\033[0m.\n'
>&2 'printf' '  \033[1m(2)\033[0m  PC.  It has \033[32mAlt\033[0m key(s) and does not have \033[33mOption\033[0m.\n'
>&2 'printf' '  \033[1m(q)\033[0m  Quit and do nothing.\n'
>&2 'printf' '\n'

# Ask the user to choose their keyboard type
while 'true'; do
  >&2 'printf' '\033[1mChoice [12q]:\033[0m '
  'read_choice'
  case "$choice" in
    '1')
      bs_key='Delete'
      zshrc_suffix='.mac'
      'break'
    ;;
    '2')
      bs_key='Backspace'
      zshrc_suffix=''
      'break'
    ;;
    'q'|'Q')
      'exit' '1'
    ;;
    "$lf")
    ;;
    *)
      >&2 'printf' '\033[33mz4h\033[0m: invalid choice: \033[31m%s\033[0m\n' "$choice"
    ;;
  esac
done

# Ask the user to choose their keybindings
>&2 'printf' '\n'
>&2 'printf' 'What \033[1mkeybindings\033[0m do you prefer?\n'
>&2 'printf' '\n'
>&2 'printf' '  \033[1m(1)\033[0m  Standard. I delete characters with \033[33m%s\033[0m key.\n' "$bs_key"
>&2 'printf' '  \033[1m(2)\033[0m  Like in \033[32mvi\033[0m. I delete characters with \033[33mX\033[0m key in \033[33mcommand mode\033[0m.\n'
>&2 'printf' '  \033[1m(q)\033[0m  Quit and do nothing.\n'
>&2 'printf' '\n'

while 'true'; do
  >&2 'printf' '\033[1mChoice [12q]:\033[0m '
  'read_choice'
  case "$choice" in
    '1')
      'break'
    ;;
    '2')
      >&2 'printf' '\n'
      >&2 'printf' 'Sorry, \033[32mvi\033[0m keybindings are \033[31mnot supported\033[0m yet.\n'
      'exit' '1'
      'break'
    ;;
    'q'|'Q')
      'exit' '1'
    ;;
    "$lf")
    ;;
    *)
      >&2 'printf' '\033[33mz4h\033[0m: invalid choice: \033[31m%s\033[0m\n' "$choice"
    ;;
  esac
done

# Ask the user if they want to use tmux
>&2 'printf' '\n'
>&2 'printf' 'Do you want \033[32mzsh\033[0m to always run in \033[32mtmux\033[0m?\n'
>&2 'printf' '\n'
>&2 'printf' '  \033[1m(y)\033[0m  Yes.\n'
>&2 'printf' '  \033[1m(n)\033[0m  No.\n'
>&2 'printf' '  \033[1m(q)\033[0m  Quit and do nothing.\n'
>&2 'printf' '\n'

while 'true'; do
  >&2 'printf' '\033[1mChoice [ynq]:\033[0m '
  'read_choice'
  case "$choice" in
    'y'|'Y')
      tmux='1'
      'break'
    ;;
    'n'|'N')
      tmux='0'
      'break'
    ;;
    'q'|'Q')
      'exit' '1'
    ;;
    "$lf")
    ;;
    *)
      >&2 'printf' '\033[33mz4h\033[0m: invalid choice: \033[31m%s\033[0m\n' "$choice"
    ;;
  esac
done

# Ask the user if they use direnv
>&2 'printf' '\n'
>&2 'printf' 'Do you use \033[32mdirenv\033[0m?\n'
>&2 'printf' '\n'
>&2 'printf' '  \033[1m(y)\033[0m  Yes.\n'
>&2 'printf' '  \033[1m(n)\033[0m  No.\n'
>&2 'printf' '  \033[1m(q)\033[0m  Quit and do nothing.\n'
>&2 'printf' '\n'

while 'true'; do
  >&2 'printf' '\033[1mChoice [ynq]:\033[0m '
  'read_choice'
  case "$choice" in
    'y'|'Y')
      direnv='1'
      'break'
    ;;
    'n'|'N')
      direnv='0'
      'break'
    ;;
    'q'|'Q')
      'exit' '1'
    ;;
    "$lf")
    ;;
    *)
      >&2 'printf' '\033[33mz4h\033[0m: invalid choice: \033[31m%s\033[0m\n' "$choice"
    ;;
  esac
done

# Initialize a list of existing Zsh configuration files
rcs=''

# Check for existing Zsh configuration files
for f in ~/'.zshenv' ~/'.zshenv.zwc'     \
         ~/'.zprofile' ~/'.zprofile.zwc' \
         ~/'.zshrc' ~/'.zshrc.zwc'       \
         ~/'.zlogin' ~/'.zlogin.zwc'     \
         ~/'.zlogout' ~/'.zlogout.zwc'; do
  if '[' '-e' "$f" ']'; then
    rcs="$rcs ${f##*/}"
  fi
done

# Initialize a variable to store the backup directory
backup_dir=''

# If there are existing Zsh configuration files, ask the user what to do with them
if '[' '-n' "$rcs" ']'; then
  backup_dir='zsh-backup'
  if command -v 'date' >'/dev/null' 2>&1; then
    backup_dir="$backup_dir/$('command' 'date' '+%Y%m%d-%H%M%S')"
  fi
  if [ '-e' "$HOME/$backup_dir" ]; then
    i='1'
    while '[' '-e' "$HOME/$backup_dir.$i" ]; do
      i="$((i+1))"
    done
    backup_dir="$backup_dir.$i"
  fi
  >&2 'printf' '\n'
  >&2 'printf' 'You have the following Zsh \033[1mstartup files\033[0m:\n'
  >&2 'printf' '\n'
  for f in $rcs; do
    >&2 'printf' '    \033[4m~/%s\033[0m\n' "$f"
  done
  >&2 'printf' '\n'
  >&2 'printf' 'What should I do with them?\n'
  >&2 'printf' '\n'
  >&2 'printf' '  \033[1m(1)\033[0m  Move them to \033[4m~/%s\033[0m. \033[1mRecommended\033[0m.\n' "$backup_dir"
  >&2 'printf' '  \033[1m(2)\033[0m  Delete them.\n'
  >&2 'printf' '  \033[1m(q)\033[0m  Quit and do nothing.\n'
  >&2 'printf' '\n'

  while 'true'; do
    >&2 'printf' '\033[1mChoice [12q]:\033[0m '
    'read_choice'
    case "$choice" in
      '1')
        backup_dir="$HOME/$backup_dir"
        'break'
      ;;
      '2')
        backup_dir=''
        'break'
      ;;
      'q'|'Q')
        'exit' '1'
      ;;
      "$lf")
      ;;
      *)
        >&2 'printf' '\033[33mz4h\033[0m: invalid choice: \033[31m%s\033[0m\n' "$choice"
      ;;
    esac
  done
  >&2 'printf' '\n'
fi

# Create temporary files for Zsh configuration
if command -v 'mktemp' >'/dev/null' 2>&1; then
  zshenv="$('command' 'mktemp' "$HOME"/.zshenv.XXXXXXXXXX)"
  zshrc="$('command' 'mktemp' "$HOME"/.zshrc.XXXXXXXXXX)"
  z4h="$('command' 'mktemp' "$HOME"/.z4h.XXXXXXXXXX)"
else
  zshenv="$HOME"/.zshenv.tmp."$$"
  zshrc="$HOME"/.zshrc.tmp."$$"
  z4h="$HOME"/.z4h.tmp."$$"
fi

# Set the URL for downloading Zsh configuration files
url='https://raw.githubusercontent.com/romkatv/zsh4humans/v5'

# Print a message indicating that the script is setting up Zsh
>&2 'printf' '\n'
>&2 'printf' 'Settings up \033[33mZsh For Humans\033[0m...\n'
>&2 'printf' '\n'

# Download the z4h.zsh file
>&2 printf '\033[33mz4h\033[0m: fetching \033[4mz4h.zsh\033[0m from \033[1mgithub.com/romkatv/zsh4humans\033[0m\n'
if ! err="$($fetch "$z4h" '--' "$url"/z4h.zsh 2>&1)"; then
  >&2 'printf' "%s\n" "$err"
  >&2 'printf' '\033[33mz4h\033[0m: failed to download \033[31m%s\033[0m\n' "$url"/z4h.zsh
  'command' 'rm' '-rf' '--' "$Z4H" 2>'/dev/null'
  'exit' '1'
fi

# Download the .zshenv file
>&2 'printf' '\033[33mz4h\033[0m: generating \033[4m~/.zshenv\033[0m\n'
if ! err="$($fetch "$zshenv" '--' "$url"/.zshenv 2>&1)"; then
  >&2 'printf' "%s\n" "$err"
  >&2 'printf' '\033[33mz4h\033[0m: failed to download \033[31m%s\033[0m\n' "$url"/.zshenv
  'exit' '1'
fi

# Download the .zshrc file
>&2 'printf' '\033[33mz4h\033[0m: generating \033[4m~/.zshrc\033[0m\n'
if ! err="$($fetch "$zshrc" '--' "$url"/.zshrc"$zshrc_suffix" 2>&1)"; then
  >&2 'printf' "%s\n" "$err"
  >&2 'printf' '\033[33mz4h\033[0m: failed to download \033[31m%s\033[0m\n' "$url"/.zshrc"$zshrc_suffix"
  'exit' '1'
fi

# Configure tmux settings
if '[' "$tmux" '=' '1' ']'; then
  'command' 'awk' "/Mark up shell's output/ {print \"# Start tmux if not already in tmux.\"; print \"zstyle ':z4h:' start-tmux command tmux -u new -A -D -t z4h\"; print \"\"; print \"# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.\"; print \"zstyle ':z4h:' prompt-at-bottom 'no'\"; print \"\"} 1" "$zshrc" >"$zshrc.bak"
else
  'command' 'awk' "/Mark up shell's output/ {print \"# Don't start tmux.\"; print \"zstyle ':z4h:' start-tmux       no\"; print \"\"} 1" "$zshrc" >"$zshrc.bak"
fi
'command' 'mv' '--' "$zshrc.bak" "$zshrc"

# Configure direnv settings
if '[' "$direnv" '=' '1' ']'; then
  'command' 'sed' '-i.bak' '-E' "/direnv.*enable/ s/'no'/'yes'/" "$zshrc"
  'command' 'rm' '-f' '--' "$zshrc".bak
fi

# Configure ssh-agent settings for Windows Subsystem for Linux
if '[' '-r' '/proc/version' ']' && 'command' 'grep' '-q' '[Mm]icrosoft' '/proc/version' 2>'/dev/null'; then
  'command' 'awk' "/Clone additional Git repositories from GitHub/ {print \"# Start ssh-agent if it's not running yet.\"; print \"zstyle ':z4h:ssh-agent:' start yes\"; print \"\"} 1" "$zshrc" >"$zshrc.bak"
  'command' 'mv' '--' "$zshrc.bak" "$zshrc"
fi

# Set the Z4H directory
Z4H="${XDG_CACHE_HOME:-$HOME/.cache}/zsh4humans/v5"

# Set the umask to prevent other users from writing to the Z4H directory
'umask' 'o-w'

# Remove any existing Z4H directory and create a new one
'command' 'rm' '-rf' '--' "$Z4H"
'command' 'mkdir' '-p' -- "$Z4H"

# If there are existing Zsh configuration files, move them to the backup directory
if '[' '-n' "$backup_dir" ']'; then
  'command' 'mkdir' '-p' '--' "$backup_dir"
  ('cd' && 'command' 'cp' '-p' '--' $rcs "$backup_dir"/) || 'exit'
fi

# Remove any existing Zsh configuration files
if '[' '-n' "$rcs" ']'; then
  ('cd' && 'command' 'rm' '-f' '--' $rcs ) || 'exit'
fi

# Move the temporary Zsh configuration files to their final locations
'command' 'mv' '--' "$zshenv" ~/'.zshenv'
'command' 'mv' '--' "$zshrc" ~/'.zshrc'
'command' 'mv' '--' "$z4h" "$Z4H"/z4h.zsh

# Create a welcome file in the Z4H directory
'printf' '%s\n' "$backup_dir" >"$Z4H"/welcome

# Run the cleanup function
'cleanup'

# Print a message indicating that the script is bootstrapping the Zsh environment
>&2 'printf' '\033[33mz4h\033[0m: bootstrapping \033[32mzsh\033[0m environment\n'

# Set up the Zsh environment
'export' ZDOTDIR="$HOME"
Z4H_BOOTSTRAPPING='1'
'set' '+ue'
'set' '--'
'.' ~/'.zshenv'
