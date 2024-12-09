#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer AgentsX {
    float data[];
} agents_x;

layout(set = 0, binding = 1, std430) restrict buffer AgentsY {
    float data[];
} agents_y;

layout(set = 0, binding = 2, std430) restrict buffer AgentsRot {
    float data[];
} agents_rot;


layout(set = 0, binding = 3, std430) restrict buffer Params {
    float width;
    float height;
    float numAgents;
    float sensorAngle;
    float sensorDist;
    float actorSpeed;
    float turnSpeed;
} params;

layout(r32f, binding = 4) uniform image2D trailMap;
layout(r32f, binding = 5) uniform image2D trailMapOut;

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main() {
    int gid = int(gl_GlobalInvocationID.x);

    float width = params.width;
    float height = params.height;

    if (gid >= params.numAgents) return;

    vec2 pos = vec2(agents_x.data[gid], agents_y.data[gid]);
    float rot = agents_rot.data[gid];

    vec2 frontSensor = vec2(
        mod(pos.x + params.sensorDist * cos(rot), width),
        mod(pos.y + params.sensorDist * sin(rot), height)
    );
    vec2 leftSensor = vec2(
        mod(pos.x + params.sensorDist * cos(rot + params.sensorAngle), width),
        mod(pos.y + params.sensorDist * sin(rot + params.sensorAngle), height)
    );
    vec2 rightSensor = vec2(
        mod(pos.x + params.sensorDist * cos(rot - params.sensorAngle), width),
        mod(pos.y + params.sensorDist * sin(rot - params.sensorAngle), height)
    );
    ivec2 frontSensori = ivec2(int(frontSensor.x), int(frontSensor.y));
    ivec2 leftSensori = ivec2(int(leftSensor.x), int(leftSensor.y));
    ivec2 rightSensori = ivec2(int(rightSensor.x), int(rightSensor.y));

    float frontValue = imageLoad(trailMap, frontSensori).r;
    float leftValue = imageLoad(trailMap, leftSensori).r;
    float rightValue = imageLoad(trailMap, rightSensori).r;

    if ((frontValue < leftValue) && (frontValue < rightValue)) {
        if (rand(rot) < 0.5) {
            rot += params.turnSpeed;
        } else {
            rot -= params.turnSpeed;
        }
    } else if (frontValue < rightValue) {
        rot -= params.turnSpeed;
    } else if (frontValue < leftValue) {
        rot += params.turnSpeed;
    }

    vec2 newPos = vec2(
        mod(pos.x + params.actorSpeed * cos(rot), width),
        mod(pos.y + params.actorSpeed * sin(rot), height)
    );
    ivec2 newPosi = ivec2(int(newPos.x), int(newPos.y));

    imageStore(trailMapOut, newPosi, vec4(1.0));
    agents_x.data[gid] = newPos.x;
    agents_y.data[gid] = newPos.y;
    agents_rot.data[gid] = rot;
}