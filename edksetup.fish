# edksetup.fish
# Ported from edksetup.sh and BaseTools/BuildEnv for Fish Shell

function edksetup
    set -g SCRIPTNAME "edksetup.fish"
    set -l RECONFIG FALSE

    # Handle Arguments
    for arg in $argv
        switch $arg
            case --reconfig
                set RECONFIG TRUE
            case --help -h '-?'
                echo "Usage: source $SCRIPTNAME [--reconfig]"
                return 0
        end
    end

    # 1. Set Workspace
    if not set -q WORKSPACE
        set -gx WORKSPACE $PWD
    end

    # 2. Set Conf Path
    if not set -q CONF_PATH
        set -gx CONF_PATH $WORKSPACE/Conf
    end

    # 3. Set EdkToolsPath (The logic from BuildEnv)
    if not set -q EDK_TOOLS_PATH
        if test -e $CONF_PATH/EdkTools
            set -gx EDK_TOOLS_PATH $CONF_PATH/EdkTools
        else if test -e $CONF_PATH/BaseToolsSource
            set -gx EDK_TOOLS_PATH $CONF_PATH/BaseToolsSource
        else if test -e $WORKSPACE/BaseTools
            set -gx EDK_TOOLS_PATH $WORKSPACE/BaseTools
        else
            echo "Unable to determine EDK_TOOLS_PATH"
            return 1
        end
    end

    # 4. Add Tools to PATH (The logic from AddEdkToolsToPath)
    # Get the Arch-specific subdir (e.g., Linux-x86_64)
    set -l BIN_SUB_DIR (uname -sm | tr ' ' '-')
    set -l EDK_TOOLS_PATH_BIN ""

    if test -e $EDK_TOOLS_PATH/BinWrappers/$BIN_SUB_DIR
        set EDK_TOOLS_PATH_BIN $EDK_TOOLS_PATH/BinWrappers/$BIN_SUB_DIR
    else
        set EDK_TOOLS_PATH_BIN $EDK_TOOLS_PATH/Bin/$BIN_SUB_DIR
    end

    # Add to PATH if not already there
    contains $EDK_TOOLS_PATH/BinWrappers/PosixLike $PATH; or set -gx PATH $EDK_TOOLS_PATH/BinWrappers/PosixLike $PATH
    contains $EDK_TOOLS_PATH_BIN $PATH; or set -gx PATH $EDK_TOOLS_PATH_BIN $PATH

    # 5. Copy Template Files (The logic from CopyTemplateFiles)
    if not test -d $CONF_PATH
        mkdir -p $CONF_PATH
    end

    for template in build_rule tools_def target
        set -l src $EDK_TOOLS_PATH/Conf/$template.template
        set -l dst $CONF_PATH/$template.txt
        if test ! -e $dst; or test "$RECONFIG" = TRUE
            echo "Copying $template template to $dst"
            cp $src $dst
        end
    end

    echo "WORKSPACE:      $WORKSPACE"
    echo "EDK_TOOLS_PATH: $EDK_TOOLS_PATH"
    echo "CONF_PATH:      $CONF_PATH"

    # Set Python default if not set
    if not set -q PYTHON_COMMAND
        set -gx PYTHON_COMMAND python3
    end
end

# Execute the function
edksetup $argv

# Cleanup function definition to keep the namespace clean
functions -e edksetup
