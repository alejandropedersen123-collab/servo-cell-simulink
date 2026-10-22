function modelFile = build_model
%BUILD_MODEL Rebuild the inspectable Simulink model from versioned source.
root=fileparts(mfilename('fullpath')); addpath(root);
model='servo_transfer_cell';
if bdIsLoaded(model), close_system(model,0); end
load_system('simulink'); new_system(model);
p=cellctl.parameters;
mw=get_param(model,'ModelWorkspace');
assignin(mw,'params',cellctl.parameter_vector(p));
defaultScenario=cellctl.scenario('nominal');
assignin(mw,'commandData',defaultScenario.commands);
assignin(mw,'plantMass',p.mass); assignin(mw,'plantViscous',p.viscous);
assignin(mw,'plantCoulomb',p.coulomb); assignin(mw,'brakeDamping',p.brakeDamping);
set_param(model,'Solver','ode4','SolverType','Fixed-step','FixedStep',num2str(p.solverStep), ...
    'StopTime','16','ReturnWorkspaceOutputs','on','SaveOutput','off','SaveTime','off');
add_block('simulink/Sources/From Workspace',[model '/Commands'], ...
    'VariableName','commandData','Interpolate','off','OutputAfterFinalValue','Holding final value', ...
    'SampleTime','0.01','Position',[20 30 130 60]);
add_block('simulink/Sources/Constant',[model '/Configuration'],'Value','params','Position',[20 100 130 130]);
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/Sequence'], 'Position',[250 30 420 165]);
setScript([model '/Sequence'],sprintf([ ...
    'function [state,target,alarm,cycles] = sequence(x,v,cmd,p)\n' ...
    'persistent mem\nif isempty(mem), mem=zeros(1,8); end\n' ...
    '[state,target,alarm,cycles,mem]=cellctl.sequence_step(x,v,cmd,p,mem);\nend\n']));
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/Servo'], 'Position',[500 50 670 195]);
setScript([model '/Servo'],sprintf([ ...
    'function [force,vref,brake] = servo(x,v,target,state,cmd,p)\n' ...
    'persistent mem\nif isempty(mem), mem=zeros(1,2); end\n' ...
    '[force,vref,brake,mem]=cellctl.servo_step(x,v,target,state,cmd(10),p,mem);\nend\n']));
add_block('simulink/Discrete/Zero-Order Hold',[model '/EncoderPosition'],'SampleTime','0.01','Position',[160 230 210 260]);
add_block('simulink/Discrete/Zero-Order Hold',[model '/EncoderVelocity'],'SampleTime','0.01','Position',[160 290 210 320]);
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/LoadAndFriction'],'Position',[760 280 940 390]);
setScript([model '/LoadAndFriction'],sprintf([ ...
    'function loss=losses(v,cmd,brake,p)\n' ...
    'loss=p(3)*v+p(4)*tanh(v/0.01)+cmd(8)+brake*p(18)*v;\nend\n']));
add_block('simulink/Math Operations/Sum',[model '/NetForce'],'Inputs','+-','Position',[770 100 800 150]);
add_block('simulink/Math Operations/Gain',[model '/InverseMass'],'Gain','1/plantMass','Position',[850 105 900 145]);
add_block('simulink/Continuous/Integrator',[model '/Velocity'],'InitialCondition','0','Position',[960 105 1000 145]);
add_block('simulink/Continuous/Integrator',[model '/Position'],'InitialCondition','0','Position',[1080 105 1120 145]);
wire('Commands/1','Sequence/3'); wire('Configuration/1','Sequence/4');
wire('EncoderPosition/1','Sequence/1'); wire('EncoderVelocity/1','Sequence/2');
wire('EncoderPosition/1','Servo/1'); wire('EncoderVelocity/1','Servo/2');
wire('Sequence/2','Servo/3'); wire('Sequence/1','Servo/4'); wire('Commands/1','Servo/5'); wire('Configuration/1','Servo/6');
wire('Servo/1','NetForce/1'); wire('LoadAndFriction/1','NetForce/2');
wire('NetForce/1','InverseMass/1'); wire('InverseMass/1','Velocity/1'); wire('Velocity/1','Position/1');
wire('Position/1','EncoderPosition/1'); wire('Velocity/1','EncoderVelocity/1');
wire('Velocity/1','LoadAndFriction/1'); wire('Commands/1','LoadAndFriction/2');
wire('Servo/3','LoadAndFriction/3'); wire('Configuration/1','LoadAndFriction/4');
signals={'Position/1','Velocity/1','Servo/1','Servo/2','Sequence/1','Sequence/2','Sequence/3','Sequence/4','Servo/3'};
names={'position','velocity','force','velocityReference','state','target','alarm','cycles','brake'};
for k=1:numel(signals)
    block=[model '/Log_' names{k}];
    add_block('simulink/Sinks/To Workspace',block,'VariableName',names{k}, ...
        'SaveFormat','Timeseries','Position',[1200 30+50*k 1300 55+50*k]);
    wire(signals{k},['Log_' names{k} '/1']);
end
Simulink.BlockDiagram.arrangeSystem(model,'FullLayout','true');
set_param(model,'ZoomFactor','FitSystem','Description', ...
    'Virtual commissioning of a servo transfer station. SI units. Software demonstration, not a certified safety controller.');
dest=fullfile(root,'models'); if ~isfolder(dest),mkdir(dest);end
modelFile=fullfile(dest,[model '.slx']); save_system(model,modelFile);
    function wire(src,dst)
        add_line(model,src,dst,'autorouting','on');
    end
end
function setScript(path,code)
chart=find(get_param(bdroot(path),'Object'),'-isa','Stateflow.EMChart','Path',path);
chart.Script=code;
end
