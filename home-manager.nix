# magpie 的 home-manager 集成：装包 + 可选的登录自启条目。
#
# enable 把包放进 home.packages；autostart.enable 再把包里那份 desktop 文件链进
# ~/.config/autostart。条目内容仍是包里的 `Exec=magpie %U`（走 PATH），所以升版后
# 永远指向当前版本。
#
# 不要手工建这个软链：手建的那条通常指向 <profile>/share/applications/magpie.desktop，
# profile 换代或 GC 掉那一代 store 路径之后链接就断了，而且断得无声无息——下次登录
# magpie 只是不自启。
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.magpie;
in
{
  options.programs.magpie = {
    enable = lib.mkEnableOption "magpie";

    autostart.enable = lib.mkEnableOption "登录时自动启动 magpie";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.magpie;
      defaultText = lib.literalExpression "pkgs.magpie";
      description = "提供 `share/applications/magpie.desktop` 的 magpie 包。";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."autostart/magpie.desktop" = lib.mkIf cfg.autostart.enable {
      # 覆盖可能已经存在的条目（例如早期手工建的软链）。
      force = true;
      source = "${cfg.package}/share/applications/magpie.desktop";
    };
  };
}
