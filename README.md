# Macropad 3x3 - ZMK Firmware

A ZMK firmware for a 3x3 macropad with Nice!Nano v2 and OLED display.

## Hardware

- **Controller**: Nice!Nano v2 (or compatible clone)
- **Display**: SSD1306 OLED 128x32 (I2C)
- **Matrix**: 3x3 (9 keys)

## Pin Assignment

### Rows
| Row | Pin |
|-----|-----|
| R0  | P0.22 (D4) |
| R1  | P0.24 (D5) |
| R2  | P1.00 (D6) |

### Columns
| Col | Pin |
|-----|-----|
| C0  | P0.11 (D7) |
| C1  | P0.31 (D8) |
| C2  | P0.30 (D9) |

### OLED Display (I2C)
| Signal | Pin |
|--------|-----|
| SDA    | P0.17 (D2) |
| SCL    | P0.20 (D3) |

## Key Mapping

### Layer 0 - Number Pad
```
| 7 | 8 | 9 |
| 4 | 5 | 6 |
| 1 | 2 | 3 |
```

### Layer 1 - Media
```
| Prev | Play  | Next  |
| Vol- | Mute  | Vol+  |
| BT1  | BT2   | BTCLR |
```

### Layer 2 - Function Keys
```
| F7 | F8 | F9 |
| F4 | F5 | F6 |
| F1 | F2 | F3 |
```

## Building the Firmware

### Option 1: GitHub Actions (recommended)

1. Create a new GitHub repository
2. Upload all files
3. GitHub Actions will automatically build the firmware
4. Download the `.uf2` file from Actions Artifacts

### Option 2: Build locally

```bash
# ZMK Setup
west init -l config
west update

# Build firmware
west build -s zmk/app -b nice_nano_v2 -- -DSHIELD=macropad3x3 -DZMK_CONFIG="$(pwd)/config"
```

## Flashing the Firmware

1. Connect the Nice!Nano v2 via USB
2. Double-press the reset button quickly (board enters bootloader mode)
3. A USB drive "NICENANO" appears
4. Copy the `.uf2` file to the drive
5. The board automatically restarts

## Customization

### Change pin assignment

Edit `config/boards/shields/macropad3x3/macropad3x3.overlay`:
- `row-gpios`: Row pins
- `col-gpios`: Column pins

### Change key mapping

Edit `config/boards/shields/macropad3x3/macropad3x3.keymap`

### Display settings

Edit `config/macropad3x3.conf` for display widgets

## Diode Direction

The firmware is configured for `col2row` (diode from column to row).
If your diodes are installed the other way around, change in the `.overlay`:

```dts
diode-direction = "row2col";
```

## Troubleshooting

### Display not working
- Check I2C connection (SDA/SCL)
- Make sure the I2C address `0x3c` is correct
- Some displays use `0x3d`

### Keys not working
- Check the diode direction
- Test the GPIO pins with a multimeter
