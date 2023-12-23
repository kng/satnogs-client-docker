#!/usr/bin/env python3
import argparse
from mcp2221 import MCP2221, find_devices
from mcp2221.enums import *
from mcp2221.exceptions import *

# Hook the gpios to a 4x relay board
# GPIO functions
# gp0: LNA Disable, LNA powered by NC contact
# gp1: Antenna select, off = < 410MHz, on = > 410MHz
# gp2: PA Enabled
# gp3: ROT Disable, Logic powered by NC contact

# udev rules needed:
# in /etc/udev/rules.d/99-mcp.rules
# SUBSYSTEM=="usb", ATTRS{idVendor}=="04d8", ATTR{idProduct}=="00dd", MODE="0660", GROUP="plugdev"


def set_outputs(arg: dict):
    try:
        mcp = MCP2221(find_devices()[0])
    except Exception as e:
        print(f'Failed to initialize MCP2221: {e}')
        return

    try:
        if 'lna' in arg:
            if int(arg['lna']) == 0:
                print('LNA disable')
                mcp.gpio0_value = True
            else:
                print('LNA enable')
                mcp.gpio0_value = False

        if 'freq' in arg:
            if int(arg['freq']) > 410000000:
                print('Set antenna to UHF')
                mcp.gpio1_value = True
            else:
                print('Set antenna to VHF')
                mcp.gpio1_value = False

        if 'pa' in arg:
            if int(arg['pa']) == 0:
                print('PA disable')
                mcp.gpio2_value = False
            else:
                print('PA enable')
                mcp.gpio2_value = True

        if 'rot' in arg:
            if int(arg['rot']) == 0:
                print('ROT disable')
                mcp.gpio3_value = True
            else:
                print('ROT enable')
                mcp.gpio3_value = False

        if 'init' in arg:
            print('Setting device defaults')
            mcp.set_default_memory_target(MemoryType.Flash)

            mcp.gpio0_write_function(GPIO0Function.GPIO)
            mcp.gpio_write_powerup_direction(0, GPIODirection.Output)
            mcp.gpio0_powerup_value = False
            mcp.gpio_write_powerup_value(0, False)

            mcp.gpio1_write_function(GPIO1Function.GPIO)
            mcp.gpio_write_powerup_direction(0, GPIODirection.Output)
            mcp.gpio1_powerup_value = False
            mcp.gpio_write_powerup_value(0, False)

            mcp.gpio2_write_function(GPIO2Function.GPIO)
            mcp.gpio_write_powerup_direction(0, GPIODirection.Output)
            mcp.gpio2_powerup_value = False
            mcp.gpio_write_powerup_value(0, False)

            mcp.gpio3_write_function(GPIO3Function.GPIO)
            mcp.gpio_write_powerup_direction(0, GPIODirection.Output)
            mcp.gpio3_powerup_value = False
            mcp.gpio_write_powerup_value(0, False)

    except (FailedCommandException, IOException, InvalidParameterException, InvalidReturnValueWarning) as e:
        print(f'MCP2221 exception {e}')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument('-f', type=int, dest='freq', help='Select antenna based on frequency [Hz]')
    parser.add_argument('-l', type=int, dest='lna', choices=(0, 1), help='LNA enable')
    parser.add_argument('-p', type=int, dest='pa', choices=(0, 1), help='PA enable')
    parser.add_argument('-r', type=int, dest='rot', choices=(0, 1), help='ROT enable')
    parser.add_argument('-i', action='store_true', dest='init', help='Program defaults to device')
    args, oth = parser.parse_known_args()
    if len(oth) > 0:
        print(f'Warning: unknown arguments passed {oth}')
    set_outputs(vars(args))
