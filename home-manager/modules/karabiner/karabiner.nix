{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  macKeyboards = [
    {
      product_id = 641;
      vendor_id = 1452;
    }
    {
      product_id = 833;
      vendor_id = 1452;
    }
  ];

  uhkConfig = {
    identifiers = {
      is_keyboard = true;
      product_id = 34304;
      vendor_id = 1452;
    };
    ignore = true;
    manipulate_caps_lock_led = false;
  };

  # Common device configuration for Mac keyboards
  macKeyboardConfig =
    { product_id, vendor_id }:
    {
      identifiers = {
        is_keyboard = true;
        inherit product_id vendor_id;
      };
      manipulate_caps_lock_led = false;
      simple_modifications = [
        {
          from.apple_vendor_top_case_key_code = "keyboard_fn";
          to = [ { key_code = "left_command"; } ];
        }
        {
          from.key_code = "down_arrow";
          to = [ { key_code = "left_command"; } ];
        }
        {
          from.key_code = "left_arrow";
          to = [ { apple_vendor_top_case_key_code = "keyboard_fn"; } ];
        }
        {
          from.key_code = "left_command";
          to = [ { key_code = "left_option"; } ];
        }
        {
          from.key_code = "left_option";
          to = [ { key_code = "left_control"; } ];
        }
        {
          from.key_code = "right_arrow";
          to = [ { key_code = "left_command"; } ];
        }
        {
          from.key_code = "right_command";
          to = [ { key_code = "right_option"; } ];
        }
        {
          from.key_code = "right_option";
          to = [ { key_code = "right_control"; } ];
        }
        {
          from.key_code = "up_arrow";
          to = [ { key_code = "left_command"; } ];
        }
      ];
    };

  karabinerConfig = {
    profiles = [
      {
        complex_modifications = {
          rules = [
            {
              description = "Alt tab hyper";
              manipulators = [
                {
                  from = {
                    key_code = "tab";
                    modifiers = {
                      mandatory = [
                        "left_command"
                        "left_control"
                      ];
                      optional = [ "any" ];
                    };
                  };
                  to = [
                    {
                      key_code = "tab";
                      modifiers = [ "left_command" ];
                    }
                  ];
                  type = "basic";
                }
              ];
            }
            {
              description = "Hyper Key (left control -> cmd+ctrl)";
              manipulators = [
                {
                  from = {
                    key_code = "left_option";
                    modifiers = {
                      optional = [ "any" ];
                    };
                  };
                  to = [
                    {
                      key_code = "left_command";
                      modifiers = [ "left_control" ];
                    }
                  ];
                  type = "basic";
                }
              ];
            }
            {
              description = "Alt tab mode";
              manipulators = [
                {
                  conditions = [
                    {
                      name = "alttabmode";
                      type = "variable_if";
                      value = true;
                    }
                  ];
                  from = {
                    key_code = "h";
                    modifiers.optional = "right_option";
                  };
                  to = [
                    {
                      key_code = "left_arrow";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
                {
                  conditions = [
                    {
                      name = "alttabmode";
                      type = "variable_if";
                      value = true;
                    }
                  ];
                  from = {
                    key_code = "j";
                    modifiers.optional = "right_option";
                  };
                  to = [
                    {
                      key_code = "down_arrow";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
                {
                  conditions = [
                    {
                      name = "alttabmode";
                      type = "variable_if";
                      value = true;
                    }
                  ];
                  from = {
                    key_code = "k";
                    modifiers.optional = "right_option";
                  };
                  to = [
                    {
                      key_code = "up_arrow";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
                {
                  conditions = [
                    {
                      name = "alttabmode";
                      type = "variable_if";
                      value = true;
                    }
                  ];
                  from = {
                    key_code = "l";
                    modifiers.optional = "right_option";
                  };
                  to = [
                    {
                      key_code = "right_arrow";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
                {
                  conditions = [
                    {
                      name = "alttabmode";
                      type = "variable_if";
                      value = true;
                    }
                  ];
                  from = {
                    key_code = "tab";
                    modifiers.optional = "right_option";
                  };
                  to = [
                    {
                      key_code = "tab";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "right_option";
                  };
                  to = [
                    {
                      key_code = "right_option";
                      lazy = true;
                    }
                  ];
                  to_after_key_up = [
                    {
                      set_variable = {
                        name = "alttabmode";
                        value = false;
                      };
                    }
                  ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "tab";
                    modifiers.mandatory = [ "right_option" ];
                  };
                  to = [
                    {
                      set_variable = {
                        name = "alttabmode";
                        value = true;
                      };
                    }
                    {
                      key_code = "tab";
                      modifiers = "right_option";
                    }
                  ];
                  type = "basic";
                }
              ];
            }
            {
              description = "Arrow / scroll mode";
              manipulators = [
                {
                  from = {
                    key_code = "j";
                    modifiers = {
                      mandatory = [
                        "right_option"
                        "left_command"
                        "left_control"
                      ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "page_down"; } ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "k";
                    modifiers = {
                      mandatory = [
                        "right_option"
                        "left_command"
                        "left_control"
                      ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "page_up"; } ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "h";
                    modifiers = {
                      mandatory = [ "right_option" ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "left_arrow"; } ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "j";
                    modifiers = {
                      mandatory = [ "right_option" ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "down_arrow"; } ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "k";
                    modifiers = {
                      mandatory = [ "right_option" ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "up_arrow"; } ];
                  type = "basic";
                }
                {
                  from = {
                    key_code = "l";
                    modifiers = {
                      mandatory = [ "right_option" ];
                      optional = [ "any" ];
                    };
                  };
                  to = [ { key_code = "right_arrow"; } ];
                  type = "basic";
                }
              ];
            }
            {
              description = "Remap other Edge";
              manipulators = [
                {
                  conditions = [
                    {
                      bundle_identifiers = [ "^com.microsoft.edgemac" ];
                      type = "frontmost_application_if";
                    }
                  ];
                  from.key_code = "fn";
                  to.key_code = "left_command";
                  type = "basic";
                }
              ];
            }
            {
              description = "Remap capslock Edge";
              manipulators = [
                {
                  conditions = [
                    {
                      bundle_identifiers = [ "^com.microsoft.edgemac" ];
                      type = "frontmost_application_if";
                    }
                  ];
                  from.key_code = "caps_lock";
                  to = [
                    {
                      key_code = "open_bracket";
                      modifiers = [ "left_control" ];
                    }
                  ];
                  type = "basic";
                }
                {
                  conditions = [
                    {
                      bundle_identifiers = [ "^com.microsoft.edgemac" ];
                      type = "frontmost_application_unless";
                    }
                  ];
                  from.key_code = "caps_lock";
                  to = [ { key_code = "escape"; } ];
                  type = "basic";
                }
              ];
            }
          ];
        };
        devices = (map (kbd: macKeyboardConfig kbd) macKeyboards) ++ [ uhkConfig ];
        name = "Default profile";
        selected = true;
        virtual_hid_keyboard = {
          country_code = 0;
          keyboard_type_v2 = "ansi";
        };
      }
      {
        name = "MS keyboard";
        virtual_hid_keyboard.country_code = 0;
      }
    ];
  };
in
{

  # Karabiner is installed via homebrew system module
  xdg.configFile = {
    "karabiner/karabiner.json".text = builtins.toJSON karabinerConfig;
  };
}
