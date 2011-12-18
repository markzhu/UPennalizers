module(..., package.seeall);
require('controller');

controller.wb_robot_init();
timeStep = controller.wb_robot_get_basic_time_step();
tDelta = .001*timeStep;

-- Get webots tags:
tags = {};

-- Minihubo joint names in webots
jointNames = {"Neck","Head",
              "LSP", "LSR", "LSY","LEP",
              "LHY", "LHR", "LHP", "LKP", "LAP", "LAR", 
              "RHY", "RHR", "RHP", "RKP", "RAP", "RAR",
              "RSP", "RSR", "RSY","REP",
	      "HY",
             };

nJoint = #jointNames;
indexHead = 1;			
nJointHead = 2;
indexLArm = 3;			--LArm: 3 4 5 6
nJointLArm = 4; 		
indexLLeg = 7;			--LLeg:7 8 9 10 11 12
nJointLLeg = 6;
indexRLeg = 13; 		--RLeg: 13 14 15 16 17 18
nJointRLeg = 6;
indexRArm = 19; 		--RArm: 19 20 21 22
nJointRArm = 4;
indexWaist = 23;
nJointWaist = 1;


jointReverse={
	3,6, --LArm:  3 4 5 6
	8,9,11,12,--LLeg: 7 8 9 10 11 12
	15,17,18,--RLeg: 13 14 15 16 17 18
	19, 20,--RArm: 19 20 21 22
	--Waist: 23
}


jointBias={
        0,0,
	-90*math.pi/180,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	-90*math.pi/180,0,0,0,
	0,
}

moveDir={};
for i=1,nJoint do moveDir[i]=1; end
for i=1,#jointReverse do moveDir[jointReverse[i]]=-1; end

tags.joints = {};
for i,v in ipairs(jointNames) do
  tags.joints[i] = controller.wb_robot_get_device(v);
  controller.wb_servo_enable_position(tags.joints[i], timeStep);
end

tags.accelerometer = controller.wb_robot_get_device("Accelerometer");
controller.wb_accelerometer_enable(tags.accelerometer, timeStep);
tags.gyro = controller.wb_robot_get_device("Gyro");
controller.wb_gyro_enable(tags.gyro, timeStep);
tags.gps = controller.wb_robot_get_device("zero");
controller.wb_gps_enable(tags.gps, timeStep);
tags.eyeled = controller.wb_robot_get_device("EyeLed");
controller.wb_led_set(tags.eyeled,0xffffff)
tags.headled = controller.wb_robot_get_device("HeadLed");
controller.wb_led_set(tags.headled,0x00ff00);


controller.wb_robot_step(timeStep);

actuator = {};
actuator.command = {};
actuator.velocity = {};
actuator.position = {};
actuator.hardness = {};

for i = 1,nJoint do
  actuator.command[i] = 0;
  actuator.velocity[i] = 0;
  actuator.position[i] = 0;
  actuator.hardness[i] = 0;
end

function set_actuator_command(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.command[index] = moveDir[index]*(a+jointBias[index]);
  else
    for i = 1,#a do
      actuator.command[index+i-1] = moveDir[index+i-1]*(a[i]+jointBias[index+i-1]);
    end
  end
end

get_time = controller.wb_robot_get_time;

function set_actuator_velocity(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.velocity[index] = a;
  else
    for i = 1,#a do
      actuator.velocity[index+i-1] = a[i];
    end
  end
end

function set_actuator_hardness(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.hardness[index] = a;
  else
    for i = 1,#a do
      actuator.hardness[index+i-1] = a[i];
    end
  end
end

function get_sensor_position(index)
  if (index) then
    return moveDir[index]*controller.wb_servo_get_position(tags.joints[index])-jointBias[index];
  else
    local t = {};
    for i = 1,nJoint do
      t[i] = moveDir[i]*controller.wb_servo_get_position(tags.joints[i])-jointBias[i];
    end
    return t;
  end
end

imuAngle = {0, 0, 0};
aImuFilter = 1 - math.exp(-tDelta/0.5);

function get_sensor_imuAngle(index)
  if (not index) then
    return imuAngle;
  else
    return imuAngle[index];
  end
end

-- Two buttons in the array
function get_sensor_button(index)
  local randThreshold = 0.001;
  if (math.random() < randThreshold) then
    return {1,0};
  else
    return {0,0};
  end
end


function get_head_position()
    local q = get_sensor_position();
    return {unpack(q, indexHead, indexHead+nJointHead-1)};
end
function get_larm_position()
  local q = get_sensor_position();
  return {unpack(q, indexLArm, indexLArm+nJointLArm-1)};
end
function get_rarm_position()
  local q = get_sensor_position();
  return {unpack(q, indexRArm, indexRArm+nJointRArm-1)};
end
function get_lleg_position()
  local q = get_sensor_position();
  return {unpack(q, indexLLeg, indexLLeg+nJointLLeg-1)};
end
function get_rleg_position()
  local q = get_sensor_position();
  return {unpack(q, indexRLeg, indexRLeg+nJointRLeg-1)};
end


function set_body_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJoint);
  end
  set_actuator_hardness(val);
end
function set_head_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointHead);
  end
  set_actuator_hardness(val, indexHead);
end
function set_larm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLArm);
  end
  set_actuator_hardness(val, indexLArm);
end
function set_rarm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRArm);
  end
  set_actuator_hardness(val, indexRArm);
end
function set_lleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLLeg);
  end
  set_actuator_hardness(val, indexLLeg);
end
function set_rleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRLeg);
  end
  set_actuator_hardness(val, indexRLeg);
end
function set_waist_hardness( val )
  set_actuator_hardness(val, indexWaist);
end
function set_head_command(val)
  set_actuator_command(val, indexHead);
end
function set_lleg_command(val)
  set_actuator_command(val, indexLLeg);
end
function set_rleg_command(val)
  set_actuator_command(val, indexRLeg);
end
function set_larm_command(val)
  set_actuator_command(val, indexLArm);
end
function set_rarm_command(val)
  set_actuator_command(val, indexRArm);
end
function set_waist_command(val)
  set_actuator_command(val, indexWaist);
end


function update()
  -- Set actuators
  for i = 1,nJoint do
    if actuator.hardness[i] > 0 then
      if actuator.velocity[i] > 0 then
        local delta = actuator.command[i] - actuator.position[i];
        local deltaMax = tDelta*actuator.velocity[i];
        if (delta > deltaMax) then
          delta = deltaMax;
        elseif (delta < -deltaMax) then
          delta = -deltaMax;
        end
        actuator.position[i] = actuator.position[i]+delta;
      else
	    actuator.position[i] = actuator.command[i];
      end
      controller.wb_servo_set_position(tags.joints[i],
                                        actuator.position[i]);
    end
  end

  if (controller.wb_robot_step(timeStep) < 0) then
    --Shut down controller:
    os.exit();
  end

  update_imu();

end


-- Extra for compatibility
function set_syncread_enable(val)
end

function set_actuator_eyeled( val )
end

function get_sensor_imuGyr0( )
  return vector.zeros(3)
end

function set_actuator_eyeled(color)
--input color is 0 to 31, so multiply by 8 to make 0-255
  code= color[1] * 0x80000 + color[2] * 0x800 + color[3]*8;
  controller.wb_led_set(tags.eyeled,code)
end

function set_actuator_headled(color)
 --input color is 0 to 31, so multiply by 8 to make 0-255
  code= color[1] * 0x80000 + color[2] * 0x800 + color[3]*8;
  controller.wb_led_set(tags.headled,code)
end

function set_indicator_state(color)
end

function set_indicator_team(teamColor)
end

function set_indicator_kickoff(kickoff)
end

function set_indicator_batteryLevel(level)
end

function set_indicator_role(role)
end

function set_indicator_ball(color)
-- color is a 3 element vector
  -- convention is all zero indicates no detection
  if( color[1]==0 and color[2]==0 and color[3]==0 ) then
    set_actuator_eyeled({15,15,15});
  else
    set_actuator_eyeled({31*color[1],31*color[2],31*color[3]});
  end

end

function set_indicator_goal(color)
-- color is a 3 element vector
  -- convention is all zero indicates no detection
  if( color[1]==0 and color[2]==0 and color[3]==0 ) then
    set_actuator_headled({15,15,15});
  else
    set_actuator_headled({31*color[1],31*color[2],31*color[3]});
  end

end

function get_battery_level()
  return 10;
end

function get_change_state()
  return 0;
end

function get_change_enable()
  return 0;
end

function get_change_team()
  return 0;
end

function get_change_role()
  return 0;
end

function get_change_kickoff()
  return 0;
end

function set_actuator_us()
end

function get_sensor_usLeft()
  return vector.zeros(10);
end

function get_sensor_usRight()
  return vector.zeros(10);
end

function set_lleg_slope(val)
end

function set_rleg_slope(val)
end

function set_lleg_slope(val)
end
function set_rleg_slope(val)
end

-- Gripper method needed
function set_gripper_hardness(val)
end

function set_gripper_command(val)
end








function update_imu()
  local imuGyrRPY = get_sensor_imuGyrNormalized();
  local accXYZ = get_sensor_imuAccXYZ();

  --Simple gyro integration
  imuAngle[1] = imuAngle[1] + tDelta * imuGyrRPY[1] * 0.9; --to compensate bodyTilt
  imuAngle[2] = imuAngle[2] + tDelta * imuGyrRPY[2] ;
  imuAngle[3] = imuAngle[3] + tDelta * imuGyrRPY[3] * 0.9; --to compensate bodyTilt

  --Update using accelerometer values 
  accX = accXYZ[1];
  accY = accXYZ[2];
  if ((accX > -1) and (accX < 1) and (accY > -1) and (accY < 1)) then
    imuAngle[1] = imuAngle[1] + aImuFilter*(-math.asin(accY) - imuAngle[1]);
    imuAngle[2] = imuAngle[2] + aImuFilter*(math.asin(accX) - imuAngle[2]);
  end

--[[

  print("GyrRPY:",imuGyrRPY[1],imuGyrRPY[2])
  print("AccXYZ:",unpack(accXYZ))
  print("AngleRP:",imuAngle[1]*180/math.pi,imuAngle[2]*180/math.pi)

  print("RPY:",
	imuAngle[1]*180/math.pi,
	imuAngle[2]*180/math.pi,
	imuAngle[3]*180/math.pi)
  --]]

end


function get_sensor_imuGyrNormalized( )
  --SJ: modified the controller wrapper function
  gyro = controller.wb_gyro_get_values(tags.gyro);

  --This is in rad/s unit
  gyro_proc={(gyro[2]-512)/0.273*math.pi/180
	, -(gyro[1]-512)/0.273*math.pi/180,
	 (gyro[3]-512)/0.273*math.pi/180};
  return gyro_proc;
end

function get_sensor_imuAccXYZ()
  accel = controller.wb_accelerometer_get_values(tags.accelerometer);
  --tested and correct
  return { (accel[1]-512)/128, -(accel[2]-512)/128 , (accel[3]-512)/128};
end

function get_sensor_imuGyr( )
  gyro = controller.wb_gyro_get_values(tags.gyro);
  --Roll Pitch Yaw 
  gyro_proc={-(gyro[2]-512)/0.273, (gyro[1]-512)/0.273,-(gyro[3]-512)/0.273};
  return gyro_proc;
end

function get_sensor_imuAcc( )
  accel = controller.wb_accelerometer_get_values(tags.accelerometer);
  return {accel[1]-512,accel[2]-512,0};
end

function get_sensor_gps()
  gps = controller.wb_gps_get_values(tags.gps);
  return gps;
end


