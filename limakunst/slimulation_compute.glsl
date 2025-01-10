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
    int numberOfGroups;
} params;

layout(r32f, binding = 4) uniform image2D trailMap;
layout(r32f, binding = 5) uniform image2D trailMapOut;

layout(set = 0, binding = 6, std430) restrict buffer AgentsGroups {
    int data[];
} agents_groups;

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec4 getColor(int groupNumber) {
    if (groupNumber == 0) {
        return vec4(1.0, 0.0, 0.0, 1.0);
    } else if (groupNumber == 1) {
        return vec4(0.0, 1.0, 0.0, 1.0);
    } else {
        return vec4(0.0, 0.0, 1.0, 1.0);
    }
}

float calculateRotation(vec4 frontColor, vec4 leftColor, vec4 rightColor, int groupNumber, float rot) {
    // Calculate weights for each side
    float frontWeight = 0.0;    
    float leftWeight = 0.0;
    float rightWeight = 0.0;


    // Calculate weights
    for (int i = 0; i < 3; i++) {
        if (i == groupNumber) {
            frontWeight += frontColor[i];
            rightWeight += rightColor[i];
            leftWeight += leftColor[i];
        } else {
            frontWeight -= 2 * frontColor[i];
            rightWeight -= 2 * rightColor[i];
            leftWeight -= 2 * leftColor[i];
        }
    }


    //Calculate rotation
    if ((frontWeight < leftWeight) && (frontWeight < rightWeight)) {
       if (rand(rot) < 0.5) {
           rot += params.turnSpeed;
       } else {
           rot -= params.turnSpeed;
       }
    } else if (frontWeight < rightWeight) {
        rot -= params.turnSpeed;
    } else if (frontWeight < leftWeight) {
        rot += params.turnSpeed;
    }

    return rot;
}

void main() {
    int gid = int(gl_GlobalInvocationID.x);

    float width = params.width;
    float height = params.height;

    if (gid >= params.numAgents) return;

    int groupNumber = agents_groups.data[gid];

    if (groupNumber >= 3) { groupNumber = 2; }

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

    vec4 frontColor = imageLoad(trailMap, frontSensori);
    vec4 leftColor = imageLoad(trailMap, leftSensori);
    vec4 rightColor = imageLoad(trailMap, rightSensori);

    rot = calculateRotation(frontColor, leftColor, rightColor, groupNumber, rot);

    vec2 newPos = vec2(
        mod(pos.x + params.actorSpeed * cos(rot), width),
        mod(pos.y + params.actorSpeed * sin(rot), height)
    );
    ivec2 newPosi = ivec2(int(newPos.x), int(newPos.y));

    vec4 outputColor = getColor(groupNumber);

    imageStore(trailMapOut, newPosi, outputColor);
    agents_x.data[gid] = newPos.x;
    agents_y.data[gid] = newPos.y;
    agents_rot.data[gid] = rot;
}