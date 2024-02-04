from scenedetect import VideoManager
from scenedetect import SceneManager
from scenedetect.detectors import ContentDetector
import sys

def find_scenes(video_path, threshold=30.0):
    video_manager = VideoManager([video_path])
    scene_manager = SceneManager()
    scene_manager.add_detector(ContentDetector(threshold=threshold))
    video_manager.set_downscale_factor()
    video_manager.start()
    scene_manager.detect_scenes(frame_source=video_manager)
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
    output_file = '/tmp/scene_timestamps.txt'
    save_scene_timestamps(video_file, output_file)


