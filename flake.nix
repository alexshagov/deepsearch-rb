{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            ruby_3_4
            bundler
            direnv
          ];

          shellHook = ''
            # Set up direnv
            eval "$(direnv hook bash)"
            
            # Set up Ruby environment
            export GEM_HOME="$PWD/.gems"
            export GEM_PATH="$GEM_HOME"
            export PATH="$GEM_HOME/bin:$PATH"

            # Create gems directory if it doesn't exist
            mkdir -p "$GEM_HOME"

            # Check if Gemfile exists and install dependencies
            GEMFILE_HASH=".gems/.gemfile.hash"
            NEW_HASH=""
            if [ -f "Gemfile" ]; then
              NEW_HASH=$(sha256sum Gemfile)
            fi

            if [ -f "Gemfile" ]; then
              if [ ! -f "$GEMFILE_HASH" ] || [ "$NEW_HASH" != "$(cat $GEMFILE_HASH)" ]; then
                echo "Gemfile has changed or gems not installed. Installing dependencies..."
                bundle install
                echo "$NEW_HASH" > "$GEMFILE_HASH"
              fi
            fi

            # Print Ruby version and gem environment info
            echo "Using Ruby: $(ruby --version)"
            echo "Gem home: $GEM_HOME"
            echo "Bundler version: $(bundle --version)"
          '';
        };
      });
}
