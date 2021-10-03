{ lib, pkgs, config, ... }:

let
  colorscheme = config.colorscheme.colors;
  wallpaper = config.wallpaper.path;
  # SSH Hosts
  sshHosts = [ "merope.local" "ubuntu@vpn.uget.express" ];
  # Programs
  discocss = "${pkgs.discocss}/bin/discocss";
  grimshot = "${pkgs.sway-contrib.grimshot}/bin/grimshot";
  gpg = "${pkgs.gnupg}/bin/gpg";
  gpg-connect-agent = "${pkgs.gnupg}/bin/gpg-connect-agent";
  kitty = "${pkgs.kitty}/bin/kitty";
  makoctl = "${pkgs.mako}/bin/makoctl";
  neomutt = "${pkgs.neomutt}/bin/neomutt";
  notify-send = "${pkgs.libnotify}/bin/notify-send";
  nvim = "${pkgs.neovim}/bin/nvim";
  octave = "${pkgs.octave}/bin/octave";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  pass-wofi = "${pkgs.pass-wofi}/bin/pass-wofi";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  preferredplayer = "${pkgs.preferredplayer}/bin/preferredplayer";
  qutebrowser = "${pkgs.qutebrowser}/bin/qutebrowser";
  setscheme-wofi = "${pkgs.setscheme-wofi}/bin/setscheme-wofi";
  ssh = "${pkgs.openssh}/bin/ssh";
  swayfader = "${pkgs.swayfader}/bin/swayfader";
  swayidle = "${pkgs.swayidle}/bin/swayidle";
  swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
  waybar = "${pkgs.waybar}/bin/waybar";
  wofi = "${pkgs.wofi}/bin/wofi";
  xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
  zathura = "${pkgs.zathura}/bin/zathura";
in rec {
  home.packages = with pkgs; [ wl-clipboard wf-recorder slurp ];
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = true;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };

  wayland.windowManager.sway = {
    enable = true;
    systemdIntegration = true;
    wrapperFeatures.gtk = true;
    config = rec {
      terminal = "${kitty}";
      menu =
        "${wofi} -D run-always_parse_args=true -k /dev/null -i -e -S run -t ${terminal}";
      fonts = {
        names = [ "Fira Sans" ];
        size = 12.0;
      };
      output = {
        DP-1 = {
          res = "1920x1080@60hz";
          pos = "0 0";
          bg = "${config.wallpaper.path} fill";
        };
        HDMI-A-1 = {
          res = "2560x1080@75hz";
          pos = "1920 0";
          bg = "${config.wallpaper.path} fill";
        };
      };
      defaultWorkspace = "workspace number 1";
      workspaceOutputAssign = [
        {
          output = "HDMI-A-1";
          workspace = "1";
        }
        {
          output = "DP-1";
          workspace = "2";
        }
      ];
      floating.criteria = [
        { app_id = "zenity"; }
        { class = "net-runelite-launcher-Launcher"; }
      ];
      colors = {
        focused = {
          border = "${colorscheme.base0C}";
          childBorder = "${colorscheme.base0C}";
          indicator = "${colorscheme.base09}";
          background = "${colorscheme.base00}";
          text = "${colorscheme.base05}";
        };
        focusedInactive = {
          border = "${colorscheme.base03}";
          childBorder = "${colorscheme.base03}";
          indicator = "${colorscheme.base03}";
          background = "${colorscheme.base00}";
          text = "${colorscheme.base04}";
        };
        unfocused = {
          border = "${colorscheme.base02}";
          childBorder = "${colorscheme.base02}";
          indicator = "${colorscheme.base02}";
          background = "${colorscheme.base00}";
          text = "${colorscheme.base03}";
        };
        urgent = {
          border = "${colorscheme.base09}";
          childBorder = "${colorscheme.base09}";
          indicator = "${colorscheme.base09}";
          background = "${colorscheme.base00}";
          text = "${colorscheme.base03}";
        };
      };
      startup = [
        # Initial lock
        {
          command = "${swaylock} -i ${wallpaper}";
        }
        # Start idle daemon
        {
          command = "${swayidle} -w";
        }
        # Focus main output
        {
          command = "swaymsg focus output HDMI-A-1";
        }
        # Add transparency
        {
          command = "${swayfader}";
        }
        # Init discocss
        {
          command = "${discocss}";
        }
        # Start waybar
        {
          command = "${waybar}";
        }
        # Set xwayland main monitor
        {
          command =
            "${xrandr} --output $(${xrandr} | grep 'XWAYLAND.*2560x1080' | awk '{printf $1}') --primary";
        }
      ];
      bars = [ ];
      window = {
        border = 2;
        commands = [
          {
            command = "move scratchpad";
            criteria = { title = "Wine System Tray"; };
          }
          {
            command = "move scratchpad";
            criteria = { title = "Firefox — Sharing Indicator"; };
          }
        ];
      };
      keybindings = lib.mkOptionDefault {
        # Splits
        "${modifier}+minus" = "split v";
        "${modifier}+backslash" = "split h";
        # Scratchpad
        "${modifier}+u" = "scratchpad show";
        "${modifier}+Shift+u" = "move scratchpad";
        # Move entire workspace
        "${modifier}+Mod1+h" = "move workspace to output left";
        "${modifier}+Mod1+Left" = "move workspace to output left";
        "${modifier}+Mod1+l" = "move workspace to output right";
        "${modifier}+Mod1+Right" = "move workspace to output right";
        # Toggle monitors
        "${modifier}+Control+Left" = "output DP-1 toggle";
        "${modifier}+Control+Down" = "output HDMI-A-1 toggle";
        # Lock screen
        "XF86Launch5" = "exec ${swaylock} --screenshots";
        # Volume
        "XF86AudioRaiseVolume" =
          "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +1%";
        "XF86AudioLowerVolume" =
          "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -1%";
        "Shift+XF86AudioRaiseVolume" =
          "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
        "Shift+XF86AudioLowerVolume" =
          "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
        "Shift+XF86AudioMute" =
          "exec ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle";
        # Media
        "XF86AudioNext" =
          "exec player=$(${preferredplayer}) && ${playerctl} next --player $player";
        "XF86AudioPrev" =
          "exec player=$(${preferredplayer}) && ${playerctl} previous --player $player";
        "XF86AudioPlay" =
          "exec player=$(${preferredplayer}) && ${playerctl} play-pause --player $player";
        "XF86AudioStop" =
          "exec player=$(${preferredplayer}) && ${playerctl} stop --player $player";
        "Shift+XF86AudioPlay" =
          "exec player=$(${playerctl} -l | ${wofi} -S dmenu) && ${preferredplayer} $player";
        "Shift+XF86AudioStop" = "exec ${preferredplayer} none";
        # Color scheme
        "XF86Tools" = "exec ${setscheme-wofi}";
        # Notifications
        "${modifier}+w" = "exec ${makoctl} dismiss";
        "${modifier}+shift+w" = "exec ${makoctl} dismiss -a";
        # Programs
        "${modifier}+v" = "exec ${terminal} -e ${nvim}";
        "${modifier}+o" = "exec ${terminal} -e ${octave}";
        "${modifier}+m" = "exec ${terminal} -e ${neomutt}";
        "${modifier}+b" = "exec ${qutebrowser}";
        "${modifier}+z" = "exec ${zathura}";
        "${modifier}+control+w" = "exec ${makoctl} invoke";
        # Screenshot
        "Print" = "exec ${grimshot} --notify copy output";
        "Shift+Print" = "exec ${grimshot} --notify copy active";
        "Control+Print" = "exec ${grimshot} --notify copy screen";
        "Mod1+Print" = "exec ${grimshot} --notify copy area";
        "${modifier}+Print" = "exec ${grimshot} --notify copy window";
        # Application menu
        "${modifier}+x" = "exec ${wofi} -S drun -I";
        # Pass wofi menu
        "Scroll_Lock" = "exec ${pass-wofi}";
        # Lock or unlock gpg
        "Shift+Scroll_Lock" = ''
          exec ${gpg-connect-agent} 'KEYINFO --no-ask B5076D6AB0783A842150876E8047AEE5604FB663 Err Pmt Des' /bye | grep " 1 " && \
          (${gpg-connect-agent} reloadagent /bye && \
          ${notify-send} "Locked" "Cleared gpg passphrase cache" -i lock -t 3000) || \
          echo "a"| ${gpg} --sign
        '';
        # Full screen across monitors
        "${modifier}+shift+f" = "fullscreen toggle global";
        # Open SSH menu
        "${modifier}+s" = ''
          exec host=$(echo '${pkgs.lib.concatStringsSep "\\n" sshHosts}' | ${wofi} -S dmenu) && \
          ${terminal} -e ${ssh} ''${host}
        '';
      };
      modifier = "Mod4";
      input = {
        "6940:6985:Corsair_CORSAIR_K70_RGB_MK.2_Mechanical_Gaming_Keyboard" = {
          xkb_layout = "br";
        };
        "6940:6985:ckb1:_CORSAIR_K70_RGB_MK.2_Mechanical_Gaming_Keyboard_vKB" =
          {
            xkb_layout = "br";
          };
        "6940:7051:ckb2:_CORSAIR_SCIMITAR_RGB_ELITE_Gaming_Mouse_vM" = {
          pointer_accel = "1";
        };
      };
      gaps = {
        horizontal = 5;
        inner = 28;
      };
    };
    # https://github.com/NixOS/nixpkgs/issues/119445#issuecomment-820507505
    extraConfig = ''
      exec dbus-update-activation-environment WAYLAND_DISPLAY
      exec systemctl --user import-environment WAYLAND_DISPLAY
    '';
  };

  programs.zsh.loginExtra = ''
    if [[ "$(tty)" == /dev/tty1 ]]; then
      exec sway
    fi
  '';
  programs.fish.loginShellInit = ''
    if test (tty) = /dev/tty1
      exec sway
    end
  '';
  programs.bash.profileExtra = ''
    if [[ "$(tty)" == /dev/tty1 ]]; then
      exec sway
    fi
  '';
}
