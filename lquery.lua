-----------------------------------------------------------------------------

-- lQuery is lua table seach lib inspired by jQuery

-- Author: rim chang jin (임창진) callin2@gmail.com

-- version : 0.1

-- dependency : Lpeg(0.9)

-----------------------------------------------------------------------------



require"re"



module(..., package.seeall);



local tQsyntax = re.compile[[

	GOAL 		<-	<EXP> ->{}  !.

	EXP			<-	<SELECTOR> ->{} (',' <SELECTOR> -> {} )*

	SELECTOR	<-	{:FT: '/'	-> '@root' :}  -> {} <FILTER>*

				/	{:FT: '*'*	-> '@whole' :} -> {} <FILTER>+

	FILTER		<-	({:FT: '/'?	-> '@down2index' :} {:IDX:<NUM> :}) -> {} -- 'get Nth node of all top nodes'

--				/	{:FT: '*'	-> '@all' :} -> {}	--	root/all

				/	{:FT: ' '	-> '@allDescendent' :} -> {} 	-- 'get all node wo/ current top nodes'

				/	{:FT: '/' 	-> '@child' :} -> {}

				/	({:FT: '#' -> '@Attr' :} {:ATTRNM: '' -> 'id' :} {:OP: '' -> '=' :} {:ARG: <ID> :}) -> {}

				/	({:FT: '.' -> '@Attr' :} {:ATTRNM: '' -> 'class' :} {:OP: '' -> '~=' :} {:ARG: <ID> :}) -> {}

				/	({:FT: '' -> '@Attr' :} {:ATTRNM: '' -> 'tag' :} {:OP: '' -> '=' :} {:ARG: <ID> :}) -> {}

				/	(<MODIFY>) -> {}

	MODIFY		<-	{:FT: '[' -> '@Attr' :} {:ATTRNM: <ID>:}  <COMPARE>? ']'

				/	{:FT: ':' -> '@index' :} {:cmd: <MODCMD> :} <MODPARAM>?

	COMPARE		<-	{:OP: '=' :} {:ARG: <COMPOPR> :}

				/	{:OP: '^=':} {:ARG: <COMPOPR> :}

				/	{:OP: '$=':} {:ARG: <COMPOPR> :}

				/	{:OP: '~=':} {:ARG: <COMPOPR> :}

	COMPOPR		<-	<NUM>

				/	<STRING>

	MODCMD		<-	'even'

				/	'odd'

				/	'eq'

	MODPARAM	<-	'(' {:ARG: <NUM>? :} ')'

	STRING		<-	'"' {[^"]*} '"'

				/	"'" {[^']*} "'"

				/	<ID>

	NUM			<-	[0-9]+

	ID			<-	[a-zA-Z][a-zA-Z0-9_]*

]]





-- meta table def it is borrowd from http://lua-users.org/wiki/LuaClassesWithMetatable

local function Class(members)

  members = members or {}

  local mt = {

    __metatable = members;

    __index     = members;

  }

  local function new(_, init)

    return setmetatable(init or {}, mt)

  end

  local function copy(obj, ...)

    local newobj = obj:new(unpack(arg))

    for n,v in pairs(obj) do newobj[n] = v end

    return newobj

  end

  members.new  = members.new  or new

  members.copy = members.copy or copy

  return mt

end



-- meta table def   END ---------------------------------------------



local function reduce(initVal,t,f)

	for k,v in pairs(t) do

		f(k,v,initVal)

	end



	return initVal

end





local function funcBind( f,...)

	return function(t)

		return f(unpack(arg),t)

	end

end



local function appendTbl(a,b)

	for i,v in ipairs(b) do

		table.insert(a,v)

	end



	return a

end





local function allNode( top )

	local tmpT = { top }



	for k,v in pairs(top) do

		if type(v) == 'table' then

			appendTbl(tmpT, allNode(v))

		end

	end



	return tmpT;

end



local function subNode(top)

	local tmpT = { }



	for k,v in pairs(top) do

		if type(v) == 'table' then

			appendTbl(tmpT, allNode(v))

		end

	end



	return tmpT;

end





local function element(t)

	return reduce({}, t ,function (k,v,initial)

		if type(v) == 'table' then

			table.insert( initial, v )

		end

	end)

end





local filterFuncMap = {

	['@root'] = function(fltConf, top)

		return top

	end,



	['@child'] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top ,function (k,v,initial)

			if type(v) == 'table' then

				appendTbl( initial, element(v) )

			end

		end)

	end,



	['@down2index'] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top ,function (k,v,initial)

			print('k' , k)

			if type(v) == 'table' and k == tonumber(fltConf.IDX) then

				table.insert( initial, v )

				--appendTbl( initial, element(v) )

			end

		end)

	end,





	['@Attr'] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top ,function (k,v,initial)

			if v[fltConf.ATTRNM] ~= nil then

				table.insert( initial, v)

			end

		end)

	end,



	['@Attr ='] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top ,function (k,v,initial)

			if v[fltConf.ATTRNM] == fltConf.ARG or v[fltConf.ATTRNM] == tonumber(fltConf.ARG) then

				table.insert( initial, v)

			end

		end)

	end,



	['@Attr ^='] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top,function (k,v,initial)

			if v[fltConf.ATTRNM] and string.sub( v[fltConf.ATTRNM], 1, string.len(fltConf.ARG) ) == fltConf.ARG then

				table.insert( initial, v)

			end

		end)

	end,



	['@Attr $='] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top,function (k,v,initial)

			if v[fltConf.ATTRNM] and string.sub( v[fltConf.ATTRNM], -string.len(fltConf.ARG), -1 ) == fltConf.ARG then

				table.insert( initial, v)

			end

		end)

	end,



	['@Attr ~='] = function(fltConf, top)

		assert( type(top) == 'table' ,'param must table')

		return reduce({}, top,function (k,v,initial)

			if v[fltConf.ATTRNM] and  string.find(v[fltConf.ATTRNM], fltConf.ARG)  then

				table.insert( initial, v)

			end

		end)

	end,



	['@whole'] = function(fltConf,  top)

		assert( type(top) == 'table' ,'param must table(as list)')

		return reduce({}, top,function (k,v,initial)

			appendTbl( initial, allNode(v) )

		end)

	end,



	['@allDescendent'] = function(fltConf,  top)

		assert( type(top) == 'table' ,'param must table(as list)')

		return reduce({}, top,function (k,v,initial)

			appendTbl( initial, subNode(v) )

		end)

	end,



}





local function filterFactory(fltConf)

--~ 	print (fltConf)

	if fltConf.OP then

		return funcBind(filterFuncMap[fltConf.FT ..' ' .. fltConf.OP], fltConf)

	else

		return funcBind(filterFuncMap[fltConf.FT], fltConf)

	end

end





local function select(top, aSelector)

	local _t = top;



--~ 	print('_t' , _t)

	for i,f in ipairs( aSelector ) do

		_t = filterFactory(f)(_t)

--~ 		print('_t' , _t)

	end



	return _t

end



local function match(top, sel)

	local r = {}



	for i,v in ipairs(sel) do

		appendTbl(r, select(top,v))

	end



	return r

end



--==============================================================================================

local tQuery = {}

local tQuery_mt = Class(tQuery)



function tQuery:new(t)

	return setmetatable( {top={t}}, tQuery_mt)

end





function tQuery:newInternal(t)

	return setmetatable( {top={unpack(t)}}, tQuery_mt)

end



function tQuery:find(p)

	local ss = re.match( p, tQsyntax)

	assert(ss, 'pattern parsing error')

	return tQuery:newInternal( match(self.top, re.match( p, tQsyntax)) )

end



function tQuery:get(idx)

	return self.top[idx]

end





function tQuery:each()

	local idx=0;



	return function()

		idx = idx+1;

		return self.top[idx]

	end

end





function new(t)

	return tQuery:new(t)

end


