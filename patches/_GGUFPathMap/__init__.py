import os, folder_paths

md = getattr(folder_paths, "models_dir", os.path.join(os.getcwd(), "models"))

folder_paths.add_model_folder_path("unet_gguf", os.path.join(md, "unet"))
folder_paths.add_model_folder_path("clip_gguf", os.path.join(md, "clip"))