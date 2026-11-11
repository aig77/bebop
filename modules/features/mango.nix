{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.mango = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.mangowm.nixosModules.mango];

    programs.mango = {
      enable = true;
      package = pkgs.mango;
    };

    home-manager.users.${username}.imports = [
      inputs.mangowm.hmModules.mango
      hm.mango
    ];

    # Checks if monitor rules are configured properly
    assertions =
      [
        {
          assertion = config.var.monitors != [];
          message = "Mango requires at least one entry in var.monitors.";
        }
      ]
      ++ map (m: {
        assertion =
          m.name != null || m.make != null || m.model != null || m.serial != null;
        message = "Each var.monitors entry needs at least one of name, make, model, or serial.";
      })
      config.var.monitors;
  };

  flake.modules.homeManager.mango = {
    config,
    lib,
    pkgs,
    var,
    ...
  }: let
    c = config.lib.stylix.colors;
    gameTag = 6;

    tagRules = map (i: "id:${toString i},no_hide:1,layout_name:scroller") (lib.range 1 6);

    # Tags 1-5 are the fixed workspaces. The gaming tag is view-only, so no
    # bind can move a window onto it; the Steam rules place games there.
    tagBinds =
      lib.concatMap (i: let
        key = toString i;
      in [
        "SUPER,${key},view,${toString i},0"
        "SUPER+SHIFT,${key},tag,${toString i},0"
      ]) (lib.range 1 5)
      ++ [
        "SUPER,${toString gameTag},view,${toString gameTag},0"
        "SUPER,G,view,${toString gameTag},0"
      ];

    sessionVariables = {
      TERMINAL = "ghostty";
      BROWSER = "zen";
      FILE_MANAGER = "thunar";
      MANGO_GAME_TAG = gameTag;
    };

    monitorRules =
      map (
        m: "${monitorId m},width:${toString m.width},height:${toString m.height},refresh:${toString m.framerate},x:${toString m.x},y:${toString m.y},scale:${toString m.scale}"
      )
      var.monitors;

    monitorId = m:
      lib.concatStringsSep "," (
        lib.filter (v: v != "") [
          (lib.optionalString (m.name != null) "name:${m.name}")
          (lib.optionalString (m.make != null) "make:${m.make}")
          (lib.optionalString (m.model != null) "model:${m.model}")
          (lib.optionalString (m.serial != null) "serial:${m.serial}")
        ]
      );
  in {
    home = {
      inherit sessionVariables;
      packages = with pkgs; [
        polkit_gnome
        playerctl
        brightnessctl
      ];
    };

    systemd.user = {inherit sessionVariables;};

    wayland.windowManager.mango = {
      enable = true;
      package = pkgs.mango;
      systemd.enable = true;
      topPrefixes = ["source"];

      settings = {
        # Noctalia writes this file; static colors below win.
        source_optional = "~/.config/mango/noctalia.conf";

        exec_once = [
          "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE TERMINAL BROWSER FILE_MANAGER"
          "systemctl --user reset-failed"
          "systemctl --user start mango-session.target"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "playerctld"
        ];

        env = [
          "TERMINAL,${sessionVariables.TERMINAL}"
          "BROWSER,${sessionVariables.BROWSER}"
          "FILE_MANAGER,${sessionVariables.FILE_MANAGER}"
          "XCURSOR_SIZE,24"
          "NIXOS_OZONE_WL,1"
          "MOZ_ENABLE_WAYLAND,1"
          "XDG_SESSION_TYPE,wayland"
          "QT_QPA_PLATFORM,wayland"
          "GDK_BACKEND,wayland"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
        ];

        # Appearance
        gap_inner_horizontal = 0;
        gap_inner_vertical = 0;
        gap_outer_horizontal = 0;
        gap_outer_vertical = 0;
        border_px = 2;
        border_radius = 0;
        focused_opacity = 1.0;
        unfocused_opacity = 1.0;
        no_border_when_single = 0;
        no_radius_when_single = 0;
        smart_gaps = 0;
        special_dim = 0;
        cursor_size = 24;
        cursor_theme = "catppuccin-mocha-dark-cursors";

        root_color = "0x${c.base00}ff";
        border_color = "0x${c.base02}ff";
        focus_color = "0x${c.base0D}ff";
        maximized_screen_color = "0x${c.base0B}ff";
        urgent_color = "0x${c.base08}ff";
        scratchpad_color = "0x${c.base0C}ff";
        global_color = "0x${c.base0E}ff";
        overlay_color = "0x${c.base0F}ff";
        split_color = "0x${c.base0E}ff";
        drop_color = "0x${c.base0D}80";

        # Effects
        blur = 1;
        blur_layer = 0;
        blur_optimized = 1;
        blur_params_radius = 8;
        blur_params_num_passes = 4;
        blur_params_noise = 0.02;
        blur_params_brightness = 0.9;
        blur_params_contrast = 0.9;
        blur_params_saturation = 1.2;
        shadows = 0;
        layer_shadows = 0;
        shadow_only_floating = 1;
        dim_enable = 0;

        # Animations
        animations = 1;
        layer_animations = 1;
        animation_type_open = "zoom";
        animation_type_close = "zoom";
        layer_animation_type_open = "slide";
        layer_animation_type_close = "slide";
        animation_fade_in = 1;
        animation_fade_out = 1;
        fade_in_begin_opacity = 0.95;
        fade_out_begin_opacity = 0.95;
        zoom_initial_ratio = 0.95;
        zoom_end_ratio = 0.95;
        animation_duration_open = 200;
        animation_duration_close = 200;
        animation_duration_move = 250;
        animation_duration_tag = 250;
        animation_duration_focus = 0;
        animation_curve_open = "0,0,0.2,1";
        animation_curve_close = "0.4,0,1,1";
        animation_curve_move = "0,0,0.2,1";
        animation_curve_tag = "0,0,0.2,1";
        animation_curve_focus = "0,0,0.2,1";
        animation_curve_opacity_fade_in = "0,0,0.2,1";
        animation_curve_opacity_fade_out = "0.4,0,1,1";
        tag_animation_direction = 0;

        # Layouts
        tag_num = 6;
        circle_layout = "scroller,tile";
        scroller_structs = 20;
        scroller_default_proportion = 0.5;
        scroller_default_proportion_single = 1.0;
        scroller_ignore_proportion_single = 0;
        scroller_focus_center = 0;
        scroller_prefer_center = 0;
        scroller_prefer_overspread = 1;
        scroller_proportion_preset = "0.33,0.5,0.66,1.0";
        edge_scroller_pointer_focus = 1;
        edge_scroller_focus_allow_speed = 0.0;
        new_is_master = 1;
        default_master_factor = 0.5;
        default_master_count = 1;
        dwindle_split_ratio = 0.5;
        dwindle_smart_split = 0;
        dwindle_horizontal_split = 1;
        dwindle_vertical_split = 1;
        dwindle_preserve_split = 1;
        tag_gather = 0;

        # Input
        repeat_rate = 25;
        repeat_delay = 600;
        numlock_on = 0;
        xkb_rules_layout = "us";
        mouse_natural_scrolling = 0;
        mouse_accel_profile = 1;
        mouse_accel_speed = 0.0;
        trackpad_natural_scrolling = 1;
        trackpad_accel_profile = 1;
        trackpad_accel_speed = 0.0;
        trackpad_click_method = 2;
        tap_to_click = 1;
        tap_and_drag = 1;
        drag_lock = 1;
        trackpad_disable_while_typing = 1;

        # Behavior
        # Mango switches tags on xdg-activation, so games and Steam popups
        # keep pulling the view back to their tag. New windows still get
        # focused through the normal map path.
        focus_on_activate = 0;
        sloppy_focus = 1;
        warp_cursor = 1;
        focus_cross_monitor = 1;
        focus_cross_tag = 0;
        cursor_hide_timeout = 3;
        enable_border_resize = 0;
        allow_tearing = 0;
        xwayland_ignore_scale = 0;
        xwayland_persistence = 1;
        allow_shortcuts_inhibit = 1;
        auto_reload_config = 1;
        scratchpad_cross_monitor = 0;
        single_scratchpad = 1;

        monitor_rule = monitorRules;

        tag_rule = tagRules;

        window_rule = [
          "no_blur:1,app_id:.*"
          "no_blur:0,app_id:^com\\.mitchellh\\.ghostty$"
          "is_floating:1,width:1000,height:750,app_id:.*[Bb]itwarden.*"
          "is_floating:1,width:800,height:600,app_id:.*blueman.*"
          "is_floating:1,width:800,height:600,app_id:.*pavucontrol.*"
          "is_floating:1,app_id:nm-connection-editor"
          "is_floating:1,title:Calculator"
          "is_floating:1,width:800,height:600,title:^(Select what to share)$"
          # Proton/Wine splash windows have no title and mango reports that as
          # "broken". Exclude it so the fullscreen rule only hits the real game
          # window and does not churn its fullscreen state.
          "is_fullscreen:1,tags:${toString gameTag},confine_pointer:1,app_id:^steam_app_,title:^(?!broken$).+"
          "is_fullscreen:1,tags:${toString gameTag},app_id:.*gamescope.*"
          "idle_inhibit_when_focus:1,app_id:.*zen.*,title:.*YouTube.*"
        ];

        layer_rule = [
          "no_animation:1,no_blur:1,layer_name:^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$"
        ];

        bind =
          [
            # Apps
            "SUPER,Return,spawn,${sessionVariables.TERMINAL}"
            "SUPER,B,spawn,${sessionVariables.BROWSER}"
            "SUPER+SHIFT,B,spawn,zen-sync-menu"
            "SUPER+SHIFT,F,spawn,${sessionVariables.FILE_MANAGER}"

            # Window management
            "SUPER,Q,killclient"
            "SUPER+SHIFT,Q,quit"
            "SUPER,T,togglefloating"
            "SUPER,F,togglefullscreen"
            "SUPER,M,togglemaximizescreen"
            "SUPER,Tab,focusstack,next"
            "SUPER+SHIFT,Tab,focusstack,prev"

            # Focus
            "SUPER,H,focusdir,left"
            "SUPER,J,focusdir,down"
            "SUPER,K,focusdir,up"
            "SUPER,L,focusdir,right"

            # Move windows
            "SUPER+SHIFT,H,exchange_client,left"
            "SUPER+SHIFT,J,exchange_client,down"
            "SUPER+SHIFT,K,exchange_client,up"
            "SUPER+SHIFT,L,exchange_client,right"

            # Scroller layout
            "SUPER,bracketright,switch_proportion_preset,next"
            "SUPER,bracketleft,switch_proportion_preset,prev"
            "SUPER,backslash,scroller_stack,right"

            # Layout switch
            "SUPER,N,switch_layout"

            # Resize
            "SUPER,right,resizewin,+10,+0"
            "SUPER,left,resizewin,-10,+0"
            "SUPER,up,resizewin,+0,-10"
            "SUPER,down,resizewin,+0,+10"

            # Scratchpad
            "SUPER,S,toggle_special_tag"
            "SUPER+SHIFT,S,tag_special_tag"

            # Noctalia
            "SUPER,SPACE,spawn,noctalia msg panel-toggle launcher"
            "SUPER,C,spawn,noctalia msg panel-toggle control-center"
            "SUPER,P,spawn,noctalia msg panel-toggle session"
            "CTRL+ALT,L,spawn,noctalia msg session lock"
            "SUPER,V,spawn,noctalia msg panel-toggle clipboard"
            "SUPER,O,spawn,noctalia msg settings-toggle"

            # Screenshots
            "NONE,Print,spawn,noctalia msg screenshot-region"
            "SHIFT,Print,spawn,noctalia msg screenshot-fullscreen"
          ]
          ++ tagBinds;

        bindl = [
          "NONE,XF86AudioRaiseVolume,spawn_shell,wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          "NONE,XF86MonBrightnessUp,spawn,brightnessctl -e4 -n2 set 5%+"
          "NONE,XF86MonBrightnessDown,spawn,brightnessctl -e4 -n2 set 5%-"
          "NONE,XF86AudioNext,spawn,playerctl next"
          "NONE,XF86AudioPlay,spawn,playerctl play-pause"
          "NONE,XF86AudioPrev,spawn,playerctl previous"
        ];

        mousebind = [
          "SUPER,btn_left,moveresize,curmove"
          "SUPER,btn_right,moveresize,curresize"
        ];

        gesturebind = [
          "none,right,3,viewprev_have_client"
          "none,left,3,viewnext_have_client"
        ];
      };
    };
  };
}
