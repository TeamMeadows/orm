---@class MeadowsORM: Atomic.Package
local package = current()
---@private
package.database = {}

-- когда вы добавляете JOIN в ваш запрос
-- он добавляет к возвращаемым данным новые колонки
-- которые вы как раз указали в JOIN.
--
-- как вы понимаете, если вы в вашей основной таблице запроса
-- будет колонка id, и в колонке которую вы указали будет колонка id
-- то поле id в ответной таблице Lua просто перепишится.
--
-- поэтому нам нужно получать от mysqloo данные в виде массива
-- чтобы на его базе определять какие колонки он вернул, и где
-- вставить таблицу указанную в JOIN
--
-- Atomic Framework предоставляет API для работы с базой данных
-- но функции предоставляемые Atomic Framework не позволяют установить
-- OPTION_NUMERIC_FIELDS на query.
-- поэтому мы пишем свою query функцию
-- которая будет использовать объект atomic.mysql._database
-- чтобы не создавать ещё одно новое соединение mysql

local db = atomic.mysql._database
local numericFields = mysqloo.OPTION_NUMERIC_FIELDS

---@private
---@async
--- WARNING: Make sure query you _ (verb) has escape the values
---@return table[]
function package.database.query(query)
  local co = coroutine.get()

  local q = db:query(query)
  q:setOption(numericFields)
  q.onSuccess = function(_, data)
    coroutine.resume(co, data)
  end

  q.onError = function(_, err)
    coroutine.resume(co, nil, err)
  end

  q:start()

  return coroutine.yield()
end