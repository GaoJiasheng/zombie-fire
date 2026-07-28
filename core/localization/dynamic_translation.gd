extends Translation

# Godot translates Label/Button text after it has been assigned. Most of this
# project predates localization and formats player-facing strings before that
# assignment (for example: "等级%d" % level). A normal Translation resource can
# only translate exact message ids, so this resource also matches catalog
# entries that contain printf-style placeholders.

const PLACEHOLDER := r"%(?:[-+ 0#]*\d*(?:\.\d+)?[diouxXeEfFgGsc])"
const CACHE_LIMIT := 2048

var _messages: Dictionary = {}
var _terms: Dictionary = {}
var _sorted_terms: Array[String] = []
var _patterns: Array[Dictionary] = []
var _cache: Dictionary = {}
var _placeholder_regex := RegEx.new()

func configure(messages: Dictionary) -> void:
	locale = "en"
	_messages = messages.duplicate(true)
	_terms = _messages.get("__terms", {}).duplicate(true)
	_messages.erase("__terms")
	_sorted_terms.assign(_terms.keys().map(func(value: Variant) -> String: return str(value)))
	_sorted_terms.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	_patterns.clear()
	_cache.clear()
	_placeholder_regex.compile(PLACEHOLDER)
	for source_var in _messages.keys():
		var source := str(source_var)
		if "%" not in source:
			continue
		var pattern := _compile_template(source)
		if pattern == null:
			continue
		_patterns.append({
			"source": source,
			"target": str(_messages[source_var]),
			"regex": pattern,
			"literal_weight": source.length() - _placeholder_count(source) * 3,
		})
	_patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("literal_weight", 0)) > int(b.get("literal_weight", 0))
	)

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var source := str(src_message)
	if _cache.has(source):
		return StringName(_cache[source])
	var translated := _translate_internal(source, 0)
	if translated != "":
		if _cache.size() >= CACHE_LIMIT:
			_cache.clear()
		_cache[source] = translated
	return StringName(translated)

func _get_plural_message(
	src_message: StringName,
	src_plural_message: StringName,
	n: int,
	context: StringName
) -> StringName:
	return _get_message(src_message if n == 1 else src_plural_message, context)

func _translate_internal(source: String, depth: int) -> String:
	if _messages.has(source):
		return str(_messages[source])
	if depth > 3 or not _contains_cjk(source):
		return ""
	# Resolve an exact reusable term before printf templates. A short template such
	# as "弱%s" must not steal "弱点", while formatted strings such as
	# "推荐 · %s" still need their authored template instead of partial replacements.
	if _terms.has(source):
		return str(_terms[source])
	for entry in _patterns:
		var regex := entry.get("regex") as RegEx
		var match := regex.search(source)
		if match == null:
			continue
		var captures: Array[String] = []
		for index in range(1, match.get_group_count() + 1):
			var value := match.get_string(index)
			var nested := _translate_internal(value, depth + 1)
			captures.append(nested if nested != "" else value)
		return _substitute(str(entry.get("target", "")), captures)
	var term_result := source
	for term in _sorted_terms:
		if term in term_result:
			term_result = term_result.replace(term, str(_terms.get(term, term)))
	if term_result != source and not _contains_cjk(term_result):
		return term_result
	return ""

func _compile_template(source: String) -> RegEx:
	var pattern := "^"
	var cursor := 0
	var capture_count := 0
	while cursor < source.length():
		if source.substr(cursor, 2) == "%%":
			pattern += "%"
			cursor += 2
			continue
		var placeholder := _placeholder_regex.search(source, cursor)
		if placeholder != null and placeholder.get_start() == cursor:
			var token := placeholder.get_string()
			pattern += "(.+?)" if token.ends_with("s") or token.ends_with("c") else "(-?[0-9][0-9.,]*)"
			capture_count += 1
			cursor = placeholder.get_end()
			continue
		var next_cursor := cursor + 1
		while next_cursor < source.length():
			if source.substr(next_cursor, 2) == "%%":
				break
			var next_placeholder := _placeholder_regex.search(source, next_cursor)
			if next_placeholder != null and next_placeholder.get_start() == next_cursor:
				break
			next_cursor += 1
		pattern += _regex_escape(source.substr(cursor, next_cursor - cursor))
		cursor = next_cursor
	pattern += "$"
	if capture_count <= 0:
		return null
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		push_error("Invalid localization template: %s" % source)
		return null
	return regex

func _substitute(target: String, captures: Array[String]) -> String:
	var result := ""
	var cursor := 0
	var capture_index := 0
	while cursor < target.length():
		if target.substr(cursor, 2) == "%%":
			result += "%"
			cursor += 2
			continue
		var placeholder := _placeholder_regex.search(target, cursor)
		if placeholder != null and placeholder.get_start() == cursor:
			result += captures[capture_index] if capture_index < captures.size() else placeholder.get_string()
			capture_index += 1
			cursor = placeholder.get_end()
			continue
		result += target.substr(cursor, 1)
		cursor += 1
	return result

func _placeholder_count(value: String) -> int:
	var count := 0
	var cursor := 0
	while cursor < value.length():
		if value.substr(cursor, 2) == "%%":
			cursor += 2
			continue
		var placeholder := _placeholder_regex.search(value, cursor)
		if placeholder == null:
			break
		count += 1
		cursor = placeholder.get_end()
	return count

func _contains_cjk(value: String) -> bool:
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if (code >= 0x3400 and code <= 0x9FFF) or (code >= 0xF900 and code <= 0xFAFF):
			return true
	return false

func _regex_escape(value: String) -> String:
	var escaped := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if character in ["\\", ".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|"]:
			escaped += "\\"
		escaped += character
	return escaped
