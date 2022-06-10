:- use_module(library(dom)).
:- use_module(library(js)).
:- dynamic(object_information/3).
:- dynamic(object_relation/3).

% object_definition(Type, Object)
object_definition(room, bedroom).
object_definition(room, bathroom).
object_definition(room, living_room).
object_definition(room, garage).
object_definition(room, dining_room).
object_definition(room, kitchen).
object_definition(room, hall).
object_definition(room, exit).
object_definition(character, player).
object_definition(character, enemy).
object_definition(item, knife).
object_definition(item, key).

% object_information(Type, Object, Value)
object_information(alive, enemy, true).

% object_relation(Type, Object1, Object2)
object_relation(location, player, bedroom).
object_relation(location, enemy, kitchen).
object_relation(location, knife, garage).
object_relation(inventory, key, enemy).

% object_relation(Type, Object1, Object2, Value)
object_relation(direction, bedroom, living_room, east).
object_relation(direction, bedroom, bathroom, south).
object_relation(direction, bathroom, bedroom, north).
object_relation(direction, living_room, dining_room, north).
object_relation(direction, living_room, hall, east).
object_relation(direction, living_room, garage, south).
object_relation(direction, living_room, bedroom, west).
object_relation(direction, garage, living_room, north).
object_relation(direction, dining_room, kitchen, east).
object_relation(direction, dining_room, living_room, south).
object_relation(direction, kitchen, dining_room, west).
object_relation(direction, hall, living_room, west).
object_relation(direction, hall, exit, east).
object_relation(direction, exit, hall, west).

init :-
    % Bind direction buttons
    get_by_id('go_north', GoNorthDom),
    get_by_id('go_east', GoEastDom),
    get_by_id('go_south', GoSouthDom),
    get_by_id('go_west', GoWestDom),
    bind(GoNorthDom, click, _, go(north)),
    bind(GoEastDom, click, _, go(east)),
    bind(GoSouthDom, click, _, go(south)),
    bind(GoWestDom, click, _, go(west)),
    % Bind keyboard keys
    get_by_tag('body', BodyDom),
    bind(BodyDom, keydown, EventDom, (
        event_property(EventDom, key, Key),
        ( Key == (w) -> go(north)
        ; Key == (a) -> go(west)
        ; Key == (s) -> go(south)
        ; Key == (d) -> go(east)
        ),
        prevent_default(EventDom)
      )
    ),
    % Update user interface
    update_ui.

go(Direction) :-
    object_relation(location, player, exit),
    (  object_relation(direction, exit, _, Direction)
    -> showMessage("Info", "Refresh the page to restart the game.")
    ;  true).

go(Direction) :-
    object_relation(location, player, hall),
    object_relation(direction, hall, exit, Direction),
    (  object_relation(inventory, key, player)
    -> (showMessage("Congrats", "You escaped the house! Refresh the page to restart the game."), false)
    ;  showMessage("Info", "You need a key to unlock the exit door.")).

go(Direction) :-
    object_relation(location, player, Location),
    object_relation(direction, Location, NewLocation, Direction),
    retract(object_relation(location, player, Location)),
    assertz(object_relation(location, player, NewLocation)),
    update_ui.

kill(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(character, Object),
    object_information(alive, Object, true),
    (  object_relation(inventory, knife, player)
    -> true
    ;  (
         atomic_list_concat(['You need a knife to kill the ', Object, '.'], '', MessageBody),
         showMessage("Info", MessageBody),
         false
       )
    ),
    % Todo: Check that character exists in the location
    % Act
    retract(object_information(alive, Object, true)),
    assertz(object_information(alive, Object, false)),
    forall(
      object_relation(inventory, Item, Object),
      (
        retract(object_relation(inventory, Item, Object)),
        assertz(object_relation(inventory, Item, player))
      )
    ),
    % Update
    update_ui.

take(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(item, Object),
    % Todo: Check that item not exists in inventory and exists in the location
    % Act
    retract(object_relation(location, Object, Location)),
    assertz(object_relation(inventory, Object, player)),
    % Update
    update_ui.

drop(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(item, Object),
    % Todo: Check that item exists in inventory and not exists in the location
    % Act
    retract(object_relation(inventory, Object, player)),
    assertz(object_relation(location, Object, Location)),
    % Update
    update_ui.

update_ui(MessageTitle, MessageBody) :-
    update_ui,
    showMessage(MessageTitle, MessageBody).

showMessage(MessageTitle, MessageBody) :-
    prop('showMessage', ShowMessage),
    apply(ShowMessage, [MessageTitle, MessageBody], _).

update_ui :-
    object_relation(location, player, PlayerLocation),
    % Update direction buttons disability
    get_by_id('go_north', GoNorthDom),
    get_by_id('go_east', GoEastDom),
    get_by_id('go_south', GoSouthDom),
    get_by_id('go_west', GoWestDom),
    (  object_relation(direction, PlayerLocation, _, north)
    -> remove_class(GoNorthDom, 'disabled')
    ;  add_class(GoNorthDom, 'disabled')
    ),
    (  object_relation(direction, PlayerLocation, _, east)
    -> remove_class(GoEastDom, 'disabled')
    ;  add_class(GoEastDom, 'disabled')
    ),
    (  object_relation(direction, PlayerLocation, _, south)
    -> remove_class(GoSouthDom, 'disabled')
    ;  add_class(GoSouthDom, 'disabled')
    ),
    (  object_relation(direction, PlayerLocation, _, west)
    -> remove_class(GoWestDom, 'disabled')
    ;  add_class(GoWestDom, 'disabled')
    ),
    % Update player location
    forall(
      get_by_class('player_location', PlayerLocationDom),
      set_html(PlayerLocationDom, PlayerLocation)
    ),
    % Update room characters
    update_object_list_ui('room_characters', character, location, PlayerLocation),
    % Update room items
    update_object_list_ui('room_items', item, location, PlayerLocation),
    % Update inventory items
    update_object_list_ui('inventory_items', item, inventory, player).

update_object_list_ui(ObjectListDomId, ObjectType, ObjectRelationType, ObjectRelatedObject) :-
    get_by_id(ObjectListDomId, ObjectListDom),
    set_html(ObjectListDom, ''),
    get_by_id('object_template', ObjectTemplateDom),
    html(ObjectTemplateDom, ObjectHtml),
    forall(
      (
        object_relation(ObjectRelationType, ObjectName, ObjectRelatedObject),
        object_definition(ObjectType, ObjectName),
        (  ObjectType == character
        -> (ObjectName \= player, object_information(alive, ObjectName, true))
        ;  true)
      ),
      (
        create('div', ObjectDom),
        html(ObjectDom, ObjectHtml),
        forall(
          get_by_class(ObjectDom, 'object_name', ObjectNameDom),
          set_html(ObjectNameDom, ObjectName)
        ),
        ( ObjectType == character -> (
            forall(
              get_by_class(ObjectDom, 'object_kill', ObjectKillDom),
              (
                remove_class(ObjectKillDom, 'visually-hidden'),
                bind(ObjectKillDom, click, _, kill(ObjectName))
              )
            )
          )
        ; (ObjectType == item, ObjectRelationType == location) -> (
            forall(
              get_by_class(ObjectDom, 'object_take', ObjectTakeDom),
              (
                remove_class(ObjectTakeDom, 'visually-hidden'),
                bind(ObjectTakeDom, click, _, take(ObjectName))
              )
            )
          )
        ; (ObjectType == item, ObjectRelationType == inventory) -> (
            forall(
              get_by_class(ObjectDom, 'object_drop', ObjectDropDom),
              (
                remove_class(ObjectDropDom, 'visually-hidden'),
                bind(ObjectDropDom, click, _, drop(ObjectName))
              )
            )
          )
        ; true
        ),
        append_child(ObjectListDom, ObjectDom)
      )
    ).