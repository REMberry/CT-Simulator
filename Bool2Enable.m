function [ result ] = Bool2Enable( input )
%BOOL2ENABLE Summary of this function goes here
%   Detailed explanation goes here
    if (input)
        result = 'on';
    else
        result = 'off';
    end

end

