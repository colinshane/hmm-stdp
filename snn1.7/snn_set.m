function net = snn_set( net, varargin )
% snn_set: sets SNN network parameters.
%
% net = snn_set( net, 'parameter', <value>, ... )
%
% Sets network parameters. The list of 'parameter'
% <value> pairs can have arbitrary length. the
% default parameters that can be set here are:
%
% name                type    default  description
% ---------------------------------------------------------------------
% train_method        string  '*'      The method used for training
% sample_method       string  '*'      The method used for sampling
% performance_method  string  '*'      The performance evaluation method
%
% A list of all wta methods can be generated by
% the function <a href = "matlab:snn_list_methods">snn_list_methods</a>.
% The train-, sample- and performance methods may add
% additional parameters to the network through their
% meta data. If the parameter list contains ...,'reset_fields', true, ...
% all fields will be newly allocated.
%
% input
%   net:       A snn network.
%              See <a href="matlab:help snn_new">snn_new</a>.
%
% output
%   net:       The modified network structure.         
%
% see also
%   <a href="matlab:help snn_parse_meta_data">snn_parse_meta_data</a>
%   <a href = "matlab:snn_list_methods">snn_list_methods</a>
%   <a href = "matlab:snn_new">snn_new</a>
%
% David Kappel 30.06.2010
%

    if (nargin<1)
        error('Not enought input arguments!');
    end

    if ~isstruct( net )
        error('Unexpected argument type for ''net''!');
    end

    [ net.train_method, reset_fields, varargin ] = ...
        snn_process_options( varargin, 'train_method', net.train_method, 'reset_fields', false );
    
    external_packages = {};

    train_fcn_name = '';

    if ~strcmp(net.train_method,'')

        train_fcn_name = snn_find_method( 'train', net.train_method );
        net.train_method = train_fcn_name(11:end);
        net.p_train_fcn = eval( ['@(net,data,ct)(',train_fcn_name,'(net,data,ct))'] );       
        train_params = snn_dispatch_meta_data( [train_fcn_name,'.m'], 'parameters', 1 );
        pack_using = snn_parse_meta_data( [train_fcn_name,'.m'], 'using', 0 );
        external_packages = { external_packages{:}, pack_using{:} };
        
        for i=1:2:length(train_params)
            if ~isfield( net, train_params{i} )
                net.( train_params{i} ) = train_params{i+1};
            end
        end
    end
    
    [ net.sample_method, varargin ] = ...
        snn_process_options( varargin, 'sample_method', net.sample_method );

    sample_fcn_name = '';
    
    if ~strcmp(net.sample_method,'')

        sample_fcn_name = snn_find_method( 'sample', net.sample_method );
        net.sample_method = sample_fcn_name(12:end);
        net.p_sample_fcn = eval( ['@(net,data,ct)(',sample_fcn_name,'(net,data,ct))'] );
        sample_params = snn_dispatch_meta_data( [sample_fcn_name,'.m'], 'parameters', 1 );
        pack_using = snn_parse_meta_data( [sample_fcn_name,'.m'], 'using', 0 );
        external_packages = { external_packages{:}, pack_using{:} };
        
        for i=1:2:length(sample_params)
            if ~isfield( net, sample_params{i} )
                net.( sample_params{i} ) = sample_params{i+1};
            end
        end
    end
    
    [ net.performance_method, unused_params ] = ...
        snn_process_options( varargin, 'performance_method', net.performance_method );

    performance_fcn_name = '';

    if ~strcmp(net.performance_method,'')

        performance_fcn_name = snn_find_method( 'performance', net.performance_method );
        net.performance_method = performance_fcn_name(17:end);
        net.p_performance_fcn = eval( ['@(net,data)(',performance_fcn_name,'(net,data))'] );
        performance_params = snn_dispatch_meta_data( [performance_fcn_name,'.m'], 'parameters', 1 );
        pack_using = snn_parse_meta_data( [performance_fcn_name,'.m'], 'using', 0 );
        external_packages = { external_packages{:}, pack_using{:} };
        
        for i=1:2:length(performance_params)
            if ~isfield( net, performance_params{i} )
                net.( performance_params{i} ) = performance_params{i+1};
            end
        end
    end

    for i=1:2:length(unused_params)
        
        if strcmp( unused_params{i}(1:2), 'p_' )
            error( 'Cant set private parameter ''%s''!', unused_params{i} );
        end
        net.( unused_params{i} ) = unused_params{i+1};
    end
    
    if ~isempty( external_packages )
        snn_include( external_packages{:} );
    end
    
    net.p_train_allocators = snn_parse_meta_data( [train_fcn_name,'.m'], 'fields', 2 );
    net.p_sample_allocators = snn_parse_meta_data( [sample_fcn_name,'.m'], 'fields', 2 );    
    net.p_performance_allocators = snn_parse_meta_data( [performance_fcn_name,'.m'], 'fields', 2 );
    
    net = snn_alloc( net, { net.p_train_allocators{:}, ...
                            net.p_sample_allocators{:}, ...
                            net.p_performance_allocators{:} }, reset_fields );
    
end
