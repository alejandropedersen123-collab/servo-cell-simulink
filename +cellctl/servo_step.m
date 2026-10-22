function [force,vref,brake,next] = servo_step(x,v,target,state,jog,p,memory)
%#codegen
%SERVO_STEP Cascaded position P / velocity PI with acceleration limit and AW.
% memory = [integral contribution in N, previous velocity reference].
I=memory(1); oldRef=memory(2); dt=p(1);
enabled=(state==1 || state==2 || state==3 || state==6);
if ~enabled || ~isfinite(x) || ~isfinite(v)
    force=0; vref=0; brake=1; next=[0 0]; return;
end
brake=0;
desired=p(8)*(target-x);
if state==6, desired=jog; end
desired=min(p(6),max(-p(6),desired));
vref=min(oldRef+p(7)*dt,max(oldRef-p(7)*dt,desired));
e=vref-v;
unsaturated=p(9)*e+I;
force=min(p(5),max(-p(5),unsaturated));
% Back-calculation prevents integrating a command the motor cannot deliver.
I=I+dt*(p(10)*e+p(11)*(force-unsaturated));
next=[I vref];
end
