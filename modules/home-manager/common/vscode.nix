{
  pkgs,
  ...
}:

let
  marketplaceExtension =
    mktplcRef: pkgs.vscode-utils.buildVscodeMarketplaceExtension { inherit mktplcRef; };

  marketplaceExtensions = [
    (marketplaceExtension {
      publisher = "fireblast";
      name = "hyprlang-vscode";
      version = "0.0.3";
      hash = "sha256-iMCyomgMGGUXaVqq1l7bgyvFgZa/W/eWHaqkA5RmExE=";
    })
    (marketplaceExtension {
      publisher = "junstyle";
      name = "vscode-django-support";
      version = "1.0.35";
      hash = "sha256-JIcOSCBqqXqXfi0S9v+9cgfjCd5keiga1Vf/PC2aUlk=";
    })
    (marketplaceExtension {
      publisher = "marioqueiros";
      name = "camelcase";
      version = "1.0.5";
      hash = "sha256-4HO0pGiTfWRrY1i1G03EDOWoEEdVEgO0VwztyJKjfTI=";
    })
    (marketplaceExtension {
      publisher = "shakram02";
      name = "bash-beautify";
      version = "0.1.1";
      hash = "sha256-pg1nGEk+cn7VlmJeDifXkXeZJLRrEFOyW0bK9W6VGfc=";
    })
    (marketplaceExtension {
      publisher = "trond-snekvik";
      name = "simple-rst";
      version = "1.5.4";
      hash = "sha256-W3LydBsc7rEHIcjE/0jESFS87uc1DfjuZt6lZhMiQcs=";
    })
    (marketplaceExtension {
      publisher = "yinfei";
      name = "luahelper";
      version = "0.2.29";
      hash = "sha256-/2RTIl3avuQb0DRciUwDYyJ/vfHjtGWyxSuB8ssYZuo=";
    })
    (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "openai";
        name = "chatgpt";
        version = "26.810.52044";
        hash = "sha256-k4hVOv6upwuKLx209KjAMMQmr9cIgSRW00qAAbLQfyc=";
      };
      vsix = pkgs.fetchurl {
        name = "openai-chatgpt-26.810.52044-linux-x64.vsix";
        url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/openai/vsextensions/chatgpt/26.810.52044/vspackage?targetPlatform=linux-x64";
        hash = "sha256-k4hVOv6upwuKLx209KjAMMQmr9cIgSRW00qAAbLQfyc=";
      };
      unpackPhase = ''
        runHook preUnpack
        ${pkgs.gzip}/bin/gunzip -c "$src" > extension.vsix
        ${pkgs.unzip}/bin/unzip -q extension.vsix
        sourceRoot=extension
        runHook postUnpack
      '';
    })
  ];
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions =
        with pkgs.vscode-extensions;
        [
          aaron-bond.better-comments
          bbenoist.nix
          bierner.color-info
          bierner.markdown-preview-github-styles
          brettm12345.nixfmt-vscode
          charliermarsh.ruff
          christian-kohler.npm-intellisense
          coolbear.systemd-unit-file
          davidanson.vscode-markdownlint
          dbaeumer.vscode-eslint
          dotjoshjohnson.xml
          eamodio.gitlens
          esbenp.prettier-vscode
          firefox-devtools.vscode-firefox-debug
          inferrinizzard.prettier-sql-vscode
          mathiasfrohlich.kotlin
          mechatroner.rainbow-csv
          mikestead.dotenv
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          ms-python.vscode-python-envs
          ms-vscode.remote-explorer
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          pkief.material-icon-theme
          quicktype.quicktype
          redhat.vscode-xml
          redhat.vscode-yaml
          samuelcolvin.jinjahtml
          tamasfe.even-better-toml
          vue.volar
        ]
        ++ marketplaceExtensions;

      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        "workbench.enableExperiments" = false;
        "settingsSync.enable" = false;
        "extensions.autoUpdate" = "off";
        "extensions.autoCheckUpdates" = false;

        "editor.formatOnSave" = true;
        "editor.formatOnSaveMode" = "modifications";
        "editor.codeActionsOnSave" = {
          "source.fixAll.eslint" = "explicit";
          "source.fixAll.ruff" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "editor.rulers" = [
          80
          88
        ];
        "editor.guides.bracketPairs" = "active";
        "editor.inlineSuggest.enabled" = true;
        "editor.largeFileOptimizations" = true;
        "editor.detectIndentation" = true;
        "editor.fontLigatures" = true;
        "editor.unicodeHighlight.allowedCharacters"."️" = true;
        "editor.accessibilitySupport" = "off";

        "files.eol" = "\n";
        "files.insertFinalNewline" = true;
        "files.trimTrailingWhitespace" = true;
        "files.exclude" = {
          "!**/.env" = true;
          "**/__pycache__" = true;
          "**/.classpath" = true;
          "**/.factorypath" = true;
          "**/.mypy_cache" = true;
          "**/.project" = true;
          "**/.pytest_cache" = true;
          "**/.settings" = true;
        };
        "files.associations"."*.html" = "jinja-html";

        "security.workspace.trust.enabled" = true;
        "security.workspace.trust.untrustedFiles" = "newWindow";
        "security.promptForLocalFileProtocolHandling" = true;

        "git.autofetch" = false;
        "git.confirmSync" = true;
        "git.showPushSuccessNotification" = false;
        "gitlens.defaultDateStyle" = "absolute";
        "gitlens.defaultDateFormat" = "YYYY-MM-DD HH:mm:ss";
        "gitlens.defaultDateShortFormat" = "YYYY-MM-DD";
        "gitlens.codeLens.scopes" = [
          "document"
          "containers"
          "blocks"
        ];

        "workbench.iconTheme" = "material-icon-theme";
        "workbench.navigationControl.enabled" = false;
        "window.controlsStyle" = "hidden";

        "python.autoComplete.addBrackets" = true;
        "python.showStartPage" = false;
        "python.autoComplete.extraPaths" = [ ];
        "python.analysis.extraPaths" = [ ];
        "python.analysis.autoImportCompletions" = true;
        "python.analysis.autoImportUserSymbols" = true;
        "python.analysis.completeFunctionParens" = true;
        "python.analysis.enableParallelIndexing" = true;
        "python.analysis.generateWithTypeAnnotation" = true;
        "python.analysis.aiHoverSummaries" = false;
        "python.analysis.analyzeUnannotatedFunctions" = false;
        "python.analysis.enableTroubleshootMissingImports" = true;
        "python.analysis.typeEvaluation.enableReachabilityAnalysis" = true;
        "python.analysis.typeCheckingMode" = "standard";
        "python.analysis.autoFormatStrings" = true;
        "python.analysis.includeExtraPathSymbolsInSymbolSearch" = true;
        "python.analysis.includeVenvInWorkspaceSymbols" = true;
        "python.analysis.typeEvaluation.deprecateTypingAliases" = true;
        "python.analysis.typeEvaluation.strictDictionaryInference" = true;
        "python.analysis.typeEvaluation.strictListInference" = true;
        "python.analysis.typeEvaluation.strictSetInference" = true;
        "python.analysis.enableDjangoSupport" = true;
        "python.diagnostics.sourceMapsEnabled" = true;
        "python.languageServer" = "Pylance";
        "python.terminal.activateEnvironment" = false;

        "yaml.schemas"."https://www.schemastore.org/traefik-v3.json" = "**/traefik.yml";
        "vue.hover.rich" = true;
        "js/ts.implicitProjectConfig.checkJs" = true;
        "js/ts.preferences.importModuleSpecifierEnding" = "js";
        "js/ts.preferences.quoteStyle" = "double";
        "cSpell.userWords" = [
          "trainerdex"
          "turnr"
        ];

        "[bash]".editor.defaultFormatter = "shakram02.bash-beautify";
        "[css]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[django-html]".editor.defaultFormatter = "junstyle.vscode-django-support";
        "[html]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[jinja-html]".editor.defaultFormatter = "vscode.html-language-features";
        "[javascript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[json]".editor.defaultFormatter = "vscode.json-language-features";
        "[jsonc]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[nix]".editor.defaultFormatter = "brettm12345.nixfmt-vscode";
        "[python]" = {
          "editor.formatOnType" = true;
          "editor.defaultFormatter" = "charliermarsh.ruff";
        };
        "[sql]".editor.defaultFormatter = "inferrinizzard.prettier-sql-vscode";
        "[typescript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[typescriptreact]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[vue]".editor.defaultFormatter = "Vue.volar";
        "[yaml]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[github-actions-workflow]".editor.defaultFormatter = "redhat.vscode-yaml";
      };

      keybindings = [
        {
          key = "tab";
          command = "-editor.action.inlineSuggest.commit";
          when = "inlineEditIsVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editor.hasSelection && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editor.hasSelection && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible";
        }
        {
          key = "tab";
          command = "-editor.action.inlineSuggest.commit";
          when = "inInlineEditsPreviewEditor";
        }
        {
          key = "shift+tab";
          command = "editor.action.inlineSuggest.jump";
          when = "inlineEditIsVisible && tabShouldJumpToInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible";
        }
        {
          key = "tab";
          command = "-editor.action.inlineSuggest.jump";
          when = "inlineEditIsVisible && tabShouldJumpToInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible";
        }
      ];
    };
  };
}
