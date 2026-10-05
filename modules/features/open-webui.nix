_: {
  flake.modules.nixos.open-webui = {config, ...}: {
    var.services.open-webui = {
      port = config.ports.open-webui;
      backup.paths = ["/var/lib/open-webui"];
      monitor = {
        enable = true;
        type = "http";
        path = "/health";
        conditions = ["[STATUS] == 200" "[BODY].status == true"];
      };
      homepage = {
        enable = true;
        title = "Open WebUI";
        icon = "si:chatbot";
      };
    };

    sops = {
      secrets = {
        "open-webui/openrouter-api-key" = {};
        "open-webui/secret-key" = {}; # maintain account persistence across restarts
      };

      templates."open-webui.env" = {
        mode = "0444";
        content = ''
          OPENAI_API_KEY=${config.sops.placeholder."open-webui/openrouter-api-key"}
          WEBUI_SECRET_KEY=${config.sops.placeholder."open-webui/secret-key"}
        '';
      };
    };

    services.open-webui = {
      enable = true;
      port = config.ports.open-webui;
      environmentFile = config.sops.templates."open-webui.env".path;
      environment = {
        OPENAI_API_BASE_URL = "https://openrouter.ai/api/v1";
        ENABLE_OLLAMA_API = "false";
        ENABLE_SIGNUP = "false";
        ANONYMIZED_TELEMETRY = "False";
        SCARF_NO_ANALYTICS = "True";
        ENABLE_COMMUNITY_SHARING = "False";
        ENABLE_TAGS_GENERATION = "True";
        ENABLE_TITLE_GENERATION = "True";
        ENABLE_AUTOCOMPLETE_GENERATION = "True";
        ENABLE_FOLLOW_UP_GENERATION = "True";
        ENABLE_RAG_WEB_SEARCH = "True";
        RAG_EMBEDDING_ENGINE = "";
        RAG_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
        ENABLE_CODE_EXECUTION = "True";
        ENABLE_CODE_INTERPRETER = "True";
        CODE_INTERPRETER_ENGINE = "pyodide";
        ENABLE_MEMORY = "True";
        ENABLE_STREAMING = "True";
      };
    };
  };
}
