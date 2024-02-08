from scenedetect import VideoStream
from scenedetect import SceneManager
from scenedetect.detectors import ContentDetector
from scenedetect.scene_detector import SceneDetector
from scenedetect import open_video
import numpy as np
import cv2
import sys


class CustomContentDetector(SceneDetector):
    def __init__(self, threshold=30.0, crop_percent=10):
        super().__init__()
        self.content_detector = ContentDetector(threshold=threshold)
        self.crop_percent = crop_percent

    def process_frame(self, frame_num, frame_img):
        # Crop the frame
        h, w = frame_img.shape[:2]
        crop_h, crop_w = int(h * self.crop_percent / 100), int(w * self.crop_percent / 100)
        cropped_frame = frame_img[crop_h:h - crop_h, crop_w:w - crop_w]

        if frame_num == 0:
            print(f"Frame shape: {frame_img.shape}, Cropped frame shape: {cropped_frame.shape}")

        # Process the cropped frame with the ContentDetector
        return self.content_detector.process_frame(frame_num, cropped_frame)
    
    def post_process(self, frame_num):
        return self.content_detector.post_process(frame_num)

def find_scenes(video_path, threshold=45.0, crop_percent=10):
    video_stream = open_video(video_path, framerate=None, backend='opencv')
    scene_manager = SceneManager()
    custom_detector = CustomContentDetector(threshold=threshold, crop_percent=crop_percent)
    scene_manager.add_detector(custom_detector)

    scene_manager.detect_scenes(video=video_stream)

    return scene_manager.get_scene_list()

def save_scene_timestamps(video_path, output_file, threshold=45.0):
    scenes = find_scenes(video_path, threshold)
    with open(output_file, 'w') as f:
        for i, scene in enumerate(scenes):
            start, end = scene[0].get_seconds(), scene[1].get_seconds()
            # Formatting the timestamps
            start_formatted = format_timestamp(start)
            end_formatted = format_timestamp(end)
            f.write(f"{start_formatted} {end_formatted}\n")

def format_timestamp(time_in_seconds):
    hours, remainder = divmod(time_in_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return '{:02}:{:02}:{:06.3f}'.format(int(hours), int(minutes), seconds)

if __name__ == "__main__":
    video_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else video_file.split('.')[0] + '_scene_changes.txt'
    save_scene_timestamps(video_file, output_file)


