function [state,target,alarm,cycles,next] = sequence_step(x,v,cmd,p,memory)
%#codegen
%SEQUENCE_STEP PLC-style scan logic. All memory is explicit and testable.
% States: 0 IDLE, 1 INDEX, 2 PROCESS, 3 RETURN, 4 COMPLETE, 5 FAULT, 6 MANUAL.
% cmd: enable,start,part,ack,estop,reset,sensorOK,load,manual,jog.
% memory: state,elapsed,stable,previousStart,cycles,alarm,previousReset,previousAck.
state=memory(1); elapsed=memory(2)+p(1); stable=memory(3);
cycles=memory(5); alarm=memory(6);
startEdge=cmd(2)>.5 && memory(4)<.5;
resetEdge=cmd(6)>.5 && memory(7)<.5;
ackEdge=cmd(4)>.5 && memory(8)<.5;
fault=0;
if cmd(5)>.5
    fault=1; % Emergency request
elseif cmd(7)<.5 || ~isfinite(x) || ~isfinite(v)
    fault=2; % Invalid feedback
elseif x < -0.03 || x > p(12)+0.08
    fault=3; % Travel limit
end
if fault>0
    if state~=5, alarm=fault; end % Preserve first-out cause.
    state=5; elapsed=0; stable=0;
elseif state==5
    % Acknowledge only while disabled and fault-free. Start is a separate edge.
    if resetEdge && cmd(1)<.5
        state=0; alarm=0; elapsed=0; stable=0;
    end
elseif cmd(1)<.5
    state=0; elapsed=0; stable=0;
else
    if state==0
        if cmd(9)>.5
            state=6; elapsed=0;
        elseif startEdge && cmd(3)>.5
            % Cycle start allowed only from the referenced home position.
            if abs(x)>p(13) || abs(v)>p(14)
                state=5; alarm=6;
            else
                state=1;
            end
            elapsed=0;
        end
    elseif state==1 || state==3
        destination=p(12); if state==3, destination=0; end
        if abs(x-destination)<p(13) && abs(v)<p(14)
            stable=stable+p(1);
        else
            stable=0;
        end
        if stable>=p(15)
            if state==1
                state=2;
            else
                state=4; cycles=cycles+1;
            end
            elapsed=0; stable=0;
        elseif elapsed>=p(16)
            state=5; alarm=4; elapsed=0;
        end
    elseif state==2
        if ackEdge
            state=3; elapsed=0;
        elseif elapsed>=p(17)
            state=5; alarm=5; elapsed=0;
        end
    elseif state==4
        % Release start before returning to idle; a held button cannot recycle.
        if cmd(2)<.5, state=0; elapsed=0; end
    elseif state==6
        if cmd(9)<.5, state=0; elapsed=0; end
    end
end
target=0;
if state==1 || state==2, target=p(12); end
next=[state elapsed stable double(cmd(2)>.5) cycles alarm double(cmd(6)>.5) double(cmd(4)>.5)];
end
