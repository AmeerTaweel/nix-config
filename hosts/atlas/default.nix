{ config, pkgs, nixpkgs, hardware, impermanence, declarative-cachix, nur, ... }:

{
  imports = [
    ./hardware-configuration.nix
    hardware.nixosModules.common-cpu-amd
    hardware.nixosModules.common-gpu-amd
    hardware.nixosModules.common-pc-ssd
    impermanence.nixosModules.impermanence
    declarative-cachix.nixosModules.declarative-cachix
    ../../modules/openrgb.nix
    ../../overlays
  ];

  # Require /data/var to be mounted at boot
  fileSystems."/data/var".neededForBoot = true;

  environment.persistence."/data" = {
    directories = [
      "/var/log"
      "/var/lib/docker"
      "/var/lib/systemd"
      "/var/lib/postgresql"
      "/srv"
    ];
  };
  system.stateVersion = "21.11";

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ nur.overlay ];
  };

  cachix = [
    {
      name = "misterio";
      sha256 = "1v4fn1m99brj9ydzzkk75h3f30rjmwz60czw2c1dnhlk6k1dsbih";
    }
  ];
  nix = {
    trustedUsers = [ "misterio" ];
    package = pkgs.nixUnstable;
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "daily";
    };
    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      warn-dirty = false
    '';
    registry.nixpkgs.flake = nixpkgs;
  };

  networking = {
    hostName = "atlas";
    networkmanager.enable = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  boot = {
    plymouth = {
      enable = true;
      font = "${pkgs.fira}/share/fonts/opentype/FiraSans-Regular.otf";
    };
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [ "quiet" "udev.log_priority=3" ];
    kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "abi.vsyscall32" = 0;
    };
    kernelModules = [ "v4l2loopback" "i2c-dev" "i2c-piix4" ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=a7III
    '';
    consoleLogLevel = 3;
    supportedFilesystems = [ "btrfs" ];
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  services = {
    /*
    pipewire = {
       enable = true;
       alsa.enable = true;
       alsa.support32Bit = true;
       pulse.enable = true;
       jack.enable = true;
     };
     */
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
    dbus.packages = [ pkgs.gcr ];
    postgresql = {
      enable = true;
      authentication = pkgs.lib.mkOverride 12 ''
        local all all trust
        host all all ::1/128 trust
      '';
    };
  };

  programs = {
    fuse.userAllowOther = true;
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };

    ssh.startAgent = false;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    gamemode = {
      enable = true;
      settings = {
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
        custom = {
          start = "${pkgs.systemd}/bin/systemctl --user stop ethminer";
          end = "${pkgs.systemd}/bin/systemctl --user start ethminer";
        };
      };
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
    dconf.enable = true;
    # droidcam.enable = true;
    kdeconnect.enable = true;
  };

  security = {
    rtkit.enable = true;
    sudo.extraConfig = ''
      Defaults timestamp_type=global
    '';
  };

  xdg.portal = {
    enable = true;
    gtkUsePortal = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr xdg-desktop-portal-gtk ];
  };

  hardware = {
    opentabletdriver.enable = true;
    ckb-next.enable = true;
    openrgb.enable = true;
    steam-hardware.enable = true;
    opengl.enable = true;
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  virtualisation.docker.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/108598
  environment.systemPackages = with pkgs;
    [
      (steam.override {
        extraProfile = ''
          unset VK_ICD_FILENAMES
          export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.i686.json:${pkgs.amdvlk}/share/vulkan/icd.d/amd_icd64.json:${pkgs.driversi686Linux.amdvlk}/share/vulkan/icd.d/amd_icd32.json
        '';
      })
    ];
}