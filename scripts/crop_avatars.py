import os
import math

def process_avatars():
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("Pillow not installed locally; will run during GitHub Actions build.")
        return

    os.makedirs('assets/avatars', exist_ok=True)
    for i in range(1, 11):
        jpg_path = f'assets/avatars/avatar_{i}.jpg'
        png_path = f'assets/avatars/avatar_{i}.png'
        if not os.path.exists(jpg_path):
            continue
        try:
            im = Image.open(jpg_path).convert('RGBA')
            w, h = im.size
            center_x, center_y = w / 2.0, h / 2.0

            # Ray-cast from outer edge inward to find colored circle boundary
            radii = []
            for angle_deg in range(0, 360, 15):
                rad = math.radians(angle_deg)
                for r in range(int(min(w, h) * 0.49), 10, -1):
                    px = int(center_x + r * math.cos(rad))
                    py = int(center_y + r * math.sin(rad))
                    if 0 <= px < w and 0 <= py < h:
                        pr, pg, pb, _ = im.getpixel((px, py))
                        if not (pr > 245 and pg > 245 and pb > 245):
                            radii.append(r)
                            break

            target_radius = max(radii) if radii else min(w, h) // 2
            # Add small 1px safety margin
            target_radius = min(target_radius + 1, min(w, h) // 2)

            crop_box = (
                max(0, int(center_x - target_radius)),
                max(0, int(center_y - target_radius)),
                min(w, int(center_x + target_radius)),
                min(h, int(center_y + target_radius)),
            )
            cropped = im.crop(crop_box).resize((512, 512), Image.Resampling.LANCZOS)

            # Circular alpha mask for transparent background
            mask = Image.new('L', (512, 512), 0)
            draw = ImageDraw.Draw(mask)
            draw.ellipse((0, 0, 512, 512), fill=255)

            cropped.putalpha(mask)
            cropped.save(png_path, 'PNG')
            print(f'Successfully generated {png_path} (detected radius: {target_radius}px)')
        except Exception as e:
            print(f'Error processing avatar_{i}: {e}')

if __name__ == '__main__':
    process_avatars()
