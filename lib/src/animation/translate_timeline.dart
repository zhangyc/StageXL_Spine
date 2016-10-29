/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class TranslateTimeline extends CurveTimeline {

  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_X = -2;
  static const int _PREV_Y = -1;
  static const int _TIME = 0;
  static const int _X = 1;
  static const int _Y = 2;

  final Float32List frames; // time, value, value, ...
  int boneIndex = 0;

  TranslateTimeline(int frameCount)
      : frames = new Float32List(frameCount * 3),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.translate.ordinal << 24) + boneIndex;
  }

  /// Sets the time and value of the specified keyframe.

  void setFrame(int frameIndex, double time, double x, double y) {
    frameIndex *= 3;
    frames[frameIndex + 0] = time.toDouble();
    frames[frameIndex + 1] = x.toDouble();
    frames[frameIndex + 2] = y.toDouble();
  }

	@override
  void apply(
			Skeleton skeleton, double lastTime, double time, List<Event> firedEvents,
			double alpha, bool setupPose, bool mixingOut) {

    Float32List frames = this.frames;
		if (time < frames[0]) return; // Time is before first frame.

		Bone bone = skeleton.bones[boneIndex];

		double x = 0.0, y = 0.0;
		if (time >= frames[frames.length - _ENTRIES]) {
      // Time is after last frame.
			x = frames[frames.length + _PREV_X];
			y = frames[frames.length + _PREV_Y];
		} else {
			// Interpolate between the previous frame and the current frame.
			int frame = Animation.binarySearch(frames, time, _ENTRIES);
			x = frames[frame + _PREV_X];
			y = frames[frame + _PREV_Y];
			double frameTime = frames[frame];
			double percent = getCurvePercent(frame ~/ _ENTRIES - 1, 1 - (time - frameTime) / (frames[frame + _PREV_TIME] - frameTime));
			x += (frames[frame + _X] - x) * percent;
			y += (frames[frame + _Y] - y) * percent;
		}

		if (setupPose) {
			bone.x = bone.data.x + x * alpha;
			bone.y = bone.data.y + y * alpha;
		} else {
			bone.x += (bone.data.x + x - bone.x) * alpha;
			bone.y += (bone.data.y + y - bone.y) * alpha;
		}
	}
}
