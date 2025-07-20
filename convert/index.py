from PIL import Image
import os

input_folder = "./pngs"
output_folder = "./webps"
os.makedirs(output_folder, exist_ok=True)

for filename in os.listdir(input_folder):
    if filename.lower().endswith(".png"):
        input_path = os.path.join(input_folder, filename)
        output_path = os.path.join(output_folder, filename.replace(".png", ".webp"))

        with Image.open(input_path) as img:
            # 투명 배경 유지
            if img.mode != "RGBA":
                img = img.convert("RGBA")

            # 저장 옵션
            img.save(
                output_path,
                "webp",
                quality=80,  # 0~100 (default: 80)
                # lossless=True,  # True = 무손실, False = 손실 압축
            )

        print(
            f"✅ {filename} → {os.path.basename(output_path)} 변환 완료 (투명 + 무손실 + quality=80)"
        )
