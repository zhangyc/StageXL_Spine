/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class DeformTimeline extends CurveTimeline {

  final Float32List frames;
  final List<Float32List> frameVertices;

  int slotIndex = 0;
  VertexAttachment attachment = null;

  DeformTimeline (int frameCount)
    : frames = new Float32List(frameCount),
      frameVertices = new List<Float32List>(frameCount),
      super(frameCount);

  /// Sets the time and value of the specified keyframe.

  void setFrame(int frameIndex, num time, Float32List vertices) {
    frames[frameIndex] = time;
    frameVertices[frameIndex] = vertices;
  }

  @override
  void apply (Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    Slot slot = skeleton.slots[slotIndex];
    VertexAttachment slotAttachment = slot.attachment as VertexAttachment;
    if (slotAttachment == null || !slotAttachment.applyDeform(attachment)) return;

    Float32List frames = this.frames;
    if (time < frames[0]) return; // Time is before first frame.

    List<Float32List> frameVertices = this.frameVertices;
    int vertexCount = frameVertices[0].length;

    Float32List vertices = slot.attachmentVertices;
    if (vertices.length != vertexCount) {
      alpha = 1; // Don't mix from uninitialized slot vertices.
      vertices = slot.attachmentVertices = new Float32List(vertexCount);
    }

    if (time >= frames[frames.length - 1]) { // Time is after last frame.
      Float32List lastVertices = frameVertices.last;
      if (alpha < 1) {
        for (int i = 0; i < vertexCount; i++) {
          vertices[i] += (lastVertices[i] - vertices[i]) * alpha;
        }
      } else {
        for (int i = 0; i < vertexCount; i++) {
          vertices[i] = lastVertices[i];
        }
      }
      return;
    }

    // Interpolate between the previous frame and the current frame.
    int frame = Animation.binarySearch1(frames, time);
    Float32List prevVertices = frameVertices[frame - 1];
    Float32List nextVertices = frameVertices[frame];
    var prevTime = frames[frame - 1];
    num frameTime = frames[frame];
    num percent = getCurvePercent(
        frame - 1, 1 - (time - frameTime) / (prevTime - frameTime));

    if (alpha < 1) {
      for (int i = 0; i < vertexCount; i++) {
        num prev = prevVertices[i];
        vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
      }
    } else {
      for (int i = 0; i < vertexCount; i++) {
        num prev = prevVertices[i];
        vertices[i] = prev + (nextVertices[i] - prev) * percent;
      }
    }
  }

}
