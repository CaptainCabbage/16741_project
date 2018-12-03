function [T_, isfound] = RRTplanning(Xstart, Xgoal, env, object, maxIter, thr)
    % T: tree of RTT planning
    % Xstart: start configuration of object, [x,y,theta]
    % Xgoal: goal configuration of object, only [theta]
    % maxIter: maximum iteration number
    % thr: the threshold allow for Xgoal

    %
    isfound = 0;
    end_ind = 0;
    [isStartOk,start_contacts] = CollisionDetection(env, object, Xstart);
    if ~isStartOk 
        error('start configuration collided!');
    end
    if isempty(start_contacts)
        error('The object is floating :-) ');
    end
    %Start to construct RTT tree
    T = RRTtree(Xstart, start_contacts, [])

    for i = 1:maxIter
        Xrand = []; % TODO: sample from random state,50% from the goal state
        [Xnear_ind, ~] = T.nearestNeighbor(T, Xrand); %TODO: in RRT tree class
        Xnear = [T.vertex(Xnear_ind).x, T.vertex(Xnear_ind).y, T.vertex(Xnear_ind).theta]
        Xnew = extend(Xrand, Xnear); % TODO
        [isXnewOk,Xnew_env_contacts] = CollisionDetection(env, object, Xnew);
        if ~isXnewOk
            continue;
        end
        
        [isXnewMotion, Xnew_finger_contacts] = isStableMotionAllowed( ) % TODO
        
        if ~isXnewMotion
            continue;
        end
        
        % combining adding vertex and edge
        T = T.add_node(T, Xnear_ind, Xnew, Xnew_env_contacts, Xnew_finger_contacts);
        [Xclosest_ind, cur_dist] = T.earestNeighbor(T, Xgoal)
        if cur_dist < thr % TODO: check if goal is reached
            isfound = 1;
            end_ind = Xclosest_ind;
            break;
        end
    end
    if end_ind ~= 0
        % display states and fingers
        T.get_path(T, end_ind);
        T_ = T;
    else
        error('no state close enough to goal state');
end