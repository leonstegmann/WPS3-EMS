classdef MinCostModel < handle
    %% Contains data for minimum cost.

    %  Copyright 2021 The MathWworks, Inc.

    properties
        MinCost
        Tout
        fisTMin
    end

    methods
        function h = MinCostModel
            reset(h)
        end

        function reset(h)
            h.MinCost = Inf;
            h.Tout = [];
            h.fisTMin = [];
        end
    end

end