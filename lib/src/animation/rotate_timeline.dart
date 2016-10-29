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

class RotateTimeline extends CurveTimeline {

  static const int _ENTRIES = 2;
  static const int _PREV_TIME = -2;
  static const int _PREV_ROTATION = -1;
  static const int _TIME = 0;
  static const int _ROTATION = 1;

  final Float32List frames; // time, value, ...
  int boneIndex = 0;

  RotateTimeline(int frameCount)
      : frames = new Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.rotate.ordinal << 24) + boneIndex;
  }

  /// Sets the time and angle of the specified keyframe.

  void setFrame(int frameIndex, double time, double degrees) {
    frameIndex = frameIndex << 1;
    frames[frameIndex + _TIME] = time.toDouble();
    frames[frameIndex + _ROTATION] = degrees.toDouble();
  }

  @override
  void apply(
			Skeleton skeleton, double lastTime, double time, List<Event> firedEvents,
			double alpha, bool setupPose, bool mixingOut) {

		if (time < this.frames[0]) return; // Time is before first frame.

		Bone bone = skeleton.bones[boneIndex];
		double r = 0.0;

		if (time >= this.frames[this.frames.length - _ENTRIES]) {
      // Time is after last frame.
			if (setupPose) {
        bone.rotation = bone.data.rotation + this.frames[this.frames.length + _PREV_ROTATION] * alpha;
      } else {
				r = bone.data.rotation + this.frames[this.frames.length + _PREV_ROTATION] - bone.rotation;
				r = _wrapRotation(r); // Wrap within -180 and 180.
				bone.rotation += r * alpha;
			}
			return;
		}

		// Interpolate between the previous frame and the current frame.
		int frame = Animation.binarySearch(this.frames, time, _ENTRIES);
		double prevRotation = this.frames[frame + _PREV_ROTATION];
		double frameTime = this.frames[frame];
		double percent = getCurvePercent((frame >> 1) - 1, 1 - (time - frameTime) / (this.frames[frame + _PREV_TIME] - frameTime));

		r = _wrapRotation(this.frames[frame + _ROTATION] - prevRotation);
		r = prevRotation + r * percent;
		if (setupPose) {
			r = _wrapRotation(r);
			bone.rotation = bone.data.rotation + r * alpha;
		} else {
			r = _wrapRotation(bone.data.rotation + r - bone.rotation);
			bone.rotation += r * alpha;
		}
	}
}
