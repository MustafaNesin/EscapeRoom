:- use_module(library(dom)).
:- use_module(library(js)).
:- use_module(library(lists)).
:- dynamic(object_information/3).
:- dynamic(object_relation/3).

% object_definition(Type, Object, Name)
object_definition(room, bedroom, 'Bedroom').
object_definition(room, bathroom, 'Bathroom').
object_definition(room, living_room, 'Living Room').
object_definition(room, garage, 'Garage').
object_definition(room, dining_room, 'Dining Room').
object_definition(room, kitchen, 'Kitchen').
object_definition(room, garden, 'Garden').
object_definition(room, hall, 'Hall').
object_definition(room, hall_exit, 'Exit').
object_definition(room, garage_exit, 'Exit').
object_definition(character, player, 'Player').
object_definition(character, enemy, 'Enemy').
object_definition(character, dog, 'Dog').
object_definition(item, leash, 'Leash').
object_definition(item, bandage, 'Bandage').
object_definition(item, garden_key, 'Garden Key').
object_definition(item, knife, 'Knife').
object_definition(item, dog_food, 'Dog Food').
object_definition(item, hall_exit_key, 'Hall Exit Key').
object_definition(item, garage_exit_key, 'Garage Exit Key').

% object_information(Type, Object, Value)
object_information(healed, player, false).
object_information(alive, enemy, true).
object_information(alive, dog, true).
object_information(petted, dog, false).
object_information(tied, dog, false).
object_information(locked, garden, true).

% object_relation(Type, Object1, Object2)
object_relation(location, player, bedroom).
object_relation(location, leash, bedroom).
object_relation(location, bandage, bathroom).
object_relation(location, knife, garage).
object_relation(location, dog_food, dining_room).
object_relation(location, enemy, kitchen).
object_relation(location, dog, garden).
object_relation(location, garden_key, hall).
object_relation(inventory, hall_exit_key, enemy).
object_relation(inventory, garage_exit_key, dog).

% object_relation(Type, Object1, Object2, Value)
object_relation(direction, bedroom, living_room, east).
object_relation(direction, bedroom, bathroom, south).
object_relation(direction, bathroom, bedroom, north).
object_relation(direction, living_room, dining_room, north).
object_relation(direction, living_room, hall, east).
object_relation(direction, living_room, garage, south).
object_relation(direction, living_room, bedroom, west).
object_relation(direction, garage, living_room, north).
object_relation(direction, garage, garden, east).
object_relation(direction, garage, garage_exit, south).
object_relation(direction, dining_room, kitchen, east).
object_relation(direction, dining_room, living_room, south).
object_relation(direction, kitchen, dining_room, west).
object_relation(direction, garden, garage, west).
object_relation(direction, hall, living_room, west).
object_relation(direction, hall, hall_exit, east).
object_relation(direction, hall_exit, hall, west).
object_relation(direction, garage_exit, garage, north).

init :-
    % Bind direction buttons
    forall(get_by_class('go_north', GoNorthDom), bind(GoNorthDom, click, _, go(north))),
    forall(get_by_class('go_east', GoEastDom), bind(GoEastDom, click, _, go(east))),
    forall(get_by_class('go_south', GoSouthDom), bind(GoSouthDom, click, _, go(south))),
    forall(get_by_class('go_west', GoWestDom), bind(GoWestDom, click, _, go(west))),
    % Bind character click events
    get_by_id('enemy', EnemyDom),
    get_by_id('dog', DogDom),
    bind(EnemyDom, click, _,
      (
        apply('disableTooltips', [], _),
        (object_relation(inventory, knife, player) -> CanKill = 1 ; CanKill = 0),
        apply('showActions',
          [
            'Actions for the enemy',
            CanKill,
            0,
            0
          ],
        _),
        get_by_id('kill_enabled_button', KillEnemyDom),
        unbind(KillEnemyDom, click),
        bind(KillEnemyDom, click, _, kill(enemy)),
        apply('enableTooltips', [], _)
      )
    ),
    bind(DogDom, click, _,
      (
        apply('disableTooltips', [], _),
        (object_relation(inventory, knife, player) -> CanKill = 1 ; CanKill = 0),
        (object_relation(inventory, dog_food, player) -> CanPet = 1 ; CanPet = 0),
        apply('showActions',
          [
            'Actions for the dog',
            CanKill,
            CanPet,
            1
          ],
        _),
        get_by_id('pet_enabled_button', PetDogDom),
        get_by_id('kill_enabled_button', KillDogDom),
        unbind(PetDogDom, click),
        unbind(KillDogDom, click),
        bind(PetDogDom, click, _, pet(dog)),
        bind(KillDogDom, click, _, kill(dog)),
        apply('enableTooltips', [], _)
      )
    ),
    % Update user interface
    update_ui.

go(Direction) :-
    object_relation(location, player, hall_exit),
    (  object_relation(direction, hall_exit, _, Direction)
    -> showMessage("Info", "Refresh the page to restart the game.")
    ;  true), !.

go(Direction) :-
    object_relation(location, player, garage_exit),
    (  object_relation(direction, garage_exit, _, Direction)
    -> showMessage("Info", "Refresh the page to restart the game.")
    ;  true), !.

% Trying to unlock the garden door
go(Direction) :-
    object_relation(location, player, Location),
    object_relation(direction, Location, garden, Direction),
    object_information(locked, garden, true),
    (  object_relation(inventory, garden_key, player)
    -> (
         retract(object_information(locked, garden, true)),
         assertz(object_information(locked, garden, false)),
         false
       )
    ;  showMessage("Info", "You need the garden key to unlock the garden door.")), !.

% Trying to unlock the hall door
go(Direction) :-
    object_relation(location, player, Location),
    object_relation(direction, Location, hall_exit, Direction),
    (  object_relation(inventory, hall_exit_key, player)
    -> (showEndMessage, false)
    ;  showMessage("Info", "You need the hall exit key to unlock the exit door.")), !.

% Trying to unlock the garage door
go(Direction) :-
    object_relation(location, player, Location),
    object_relation(direction, Location, garage_exit, Direction),
    (  object_relation(inventory, garage_exit_key, player)
    -> (showEndMessage, false)
    ;  showMessage("Info", "You need the garage exit key to unlock the exit door.")), !.

go(Direction) :-
    object_relation(location, player, Location),
    object_relation(direction, Location, NewLocation, Direction),
    retract(object_relation(location, player, Location)),
    assertz(object_relation(location, player, NewLocation)),
    update_ui.

pet(dog) :-
    % Check
    object_relation(location, player, Location),
    object_definition(character, dog, _),
    object_information(alive, dog, true),
    (  object_relation(inventory, dog_food, player)
    -> true
    ;  (
         showMessage("Info", "You need food to pet the dog."),
         false
       )
    ),
    % Todo: Check the dog exists in the location
    % Act
    forall(
      object_relation(inventory, Item, dog),
      (
        retract(object_relation(inventory, Item, dog)),
        assertz(object_relation(inventory, Item, player))
      )
    ),
    (  object_information(petted, dog, false)
    -> (
         (
            object_relation(inventory, leash, player)
         -> (
              retract(object_relation(location, dog, Location)),
              retract(object_information(tied, dog, false)),
              assertz(object_information(tied, dog, true)),
              retract(object_relation(inventory, leash, player)),
              showMessage("Info", "You have successfully retrieved the key from the dog's neck. You also tied him with the leash and took with you.")
            )
         ;  (
              showMessage("Info", "You have successfully retrieved the key from the dog's neck.")
            )
         ),
         retract(object_relation(inventory, dog_food, player)),
         retract(object_information(petted, dog, false)),
         assertz(object_information(petted, dog, true))
       )
    ;  true),
    % Update
    update_ui, !.

kill(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(character, Object, ObjectName),
    object_information(alive, Object, true),
    (  object_information(healed, player, true)
    -> true
    ;  (
         atomic_list_concat(['You need to heal yourself before attacking the ', ObjectName, '.'], '', MessageBody),
         showMessage("Info", MessageBody),
         false
       )
    ),
    (  object_relation(inventory, knife, player)
    -> true
    ;  (
         atomic_list_concat(['You need a knife to kill the ', ObjectName, '.'], '', MessageBody),
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
        assertz(object_relation(inventory, Item, player)),
        % Temporary solution
        object_definition(_, Item, ItemName),
        atomic_list_concat(['You have killed the ', ObjectName, ' and got the ', ItemName, '.'], '', MessageBody),
        showMessage("Info", MessageBody)
      )
    ),
    % Update
    update_ui, !.

take(bandage) :-
    % Check
    object_relation(location, player, Location),
    object_definition(item, bandage, _),
    % Todo: Check that item not exists in inventory and exists in the location
    % Act
    retract(object_relation(location, bandage, Location)),
    retract(object_information(healed, player, false)),
    assertz(object_information(healed, player, true)),
    showMessage("Info", "You just healed yourself."),
    % Update
    update_ui, !.

take(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(item, Object, _),
    (  setof(Item, object_relation(inventory, Item, player), Items)
    -> (
         length(Items, ItemsLength),
         write(ItemsLength),
         '@<'(ItemsLength, 2)
       )
    ;  true
    ),
    % Todo: Check that item not exists in inventory and exists in the location
    % Act
    retract(object_relation(location, Object, Location)),
    assertz(object_relation(inventory, Object, player)),
    % Update
    update_ui, !.

take(_) :-
    showMessage("Info", "Your inventory is full! Drop some items to make room in your inventory.").

drop(Object) :-
    % Check
    object_relation(location, player, Location),
    object_definition(item, Object, _),
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
    apply('showMessage', [MessageTitle, MessageBody], _).

showEndMessage :-
    get_by_id('game', GameDom),
    add_class(GameDom, 'visually-hidden'),
    (  object_information(alive, enemy, true)
    -> (
         object_information(tied, dog, true)
         -> apply('showEnd', ["You escaped the house with your dog! You hope that the man who kidnapped you won't find you again."], _)
         ;  (  object_information(alive, dog, true)
            -> apply('showEnd', ["You escaped the house! You hope that the man who kidnapped you won't find you again."], _)
            ;  apply('showEnd', ["You escaped the house but you feel remorse for killing the dog and hope the man won't find you again."], _)
            )
       )
    ;  (
         object_information(tied, dog, true)
         -> (
               object_relation(inventory, knife, player)
            -> apply('showEnd', ["You escaped the house with your dog!"], _)
            ;  apply('showEnd', ["You escaped the house with your dog but police looking for you because you left the knife at home."], _)
            )
         ;  (  object_information(alive, dog, true)
            -> (
                  object_relation(inventory, knife, player)
               -> apply('showEnd', ["You escaped the house!"], _)
               ;  apply('showEnd', ["You escaped the house but police looking for you because you left the knife at home."], _)
               )
            ;  (
                  object_relation(inventory, knife, player)
               -> apply('showEnd', ["You escaped the house but you feel remorse for killing the dog."], _)
               ;  apply('showEnd', ["You escaped the house but police looking for you because you left the knife at home."], _)
               )
            )
       )
    ).

update_ui :-
    apply('disableTooltips', [], _),
    object_relation(location, player, PlayerLocation),
    object_definition(room, PlayerLocation, PlayerLocationName),
    get_by_id('room_img', RoomImageDom),
    atomic_list_concat(['./img/', PlayerLocation, '.jpg'], '', RoomImage),
    set_attr(RoomImageDom, 'src', RoomImage),
    set_attr(RoomImageDom, 'alt', PlayerLocationName),
    % Update direction buttons visibility
    forall(
      get_by_class('go_north', GoNorthDom),
      (  object_relation(direction, PlayerLocation, NorthLocation, north)
      -> (
           remove_class(GoNorthDom, 'visually-hidden'),
           object_definition(room, NorthLocation, NorthLocationName),
           set_html(GoNorthDom, NorthLocationName)
         )
      ;  add_class(GoNorthDom, 'visually-hidden')
      )
    ),
    forall(
      get_by_class('go_east', GoEastDom),
      (  object_relation(direction, PlayerLocation, EastLocation, east)
      -> (
           remove_class(GoEastDom, 'visually-hidden'),
           object_definition(room, EastLocation, EastLocationName),
           set_html(GoEastDom, EastLocationName)
         )
      ;  add_class(GoEastDom, 'visually-hidden')
      )
    ),
    forall(
      get_by_class('go_south', GoSouthDom),
      (  object_relation(direction, PlayerLocation, SouthLocation, south)
      -> (
           remove_class(GoSouthDom, 'visually-hidden'),
           object_definition(room, SouthLocation, SouthLocationName),
           set_html(GoSouthDom, SouthLocationName)
         )
      ;  add_class(GoSouthDom, 'visually-hidden')
      )
    ),
    forall(
      get_by_class('go_west', GoWestDom),
      (  object_relation(direction, PlayerLocation, WestLocation, west)
      -> (
           remove_class(GoWestDom, 'visually-hidden'),
           object_definition(room, WestLocation, WestLocationName),
           set_html(GoWestDom, WestLocationName)
         )
      ;  add_class(GoWestDom, 'visually-hidden')
      )
    ),
    % Update player location
    forall(
      get_by_class('player_location', PlayerLocationDom),
      set_html(PlayerLocationDom, PlayerLocationName)
    ),
    % Update room characters
    forall(
      (
        object_definition(character, Character, _),
        Character \= player,
        get_by_id(Character, CharacterDom)
      ),
      (
        (
          object_relation(location, Character, PlayerLocation),
          object_information(alive, Character, true)
        )
        -> remove_class(CharacterDom, 'visually-hidden')
        ;  add_class(CharacterDom, 'visually-hidden')
      )
    ),
    % Update room items
    get_by_id('room_items', RoomItemListDom),
    set_html(RoomItemListDom, ''),
    forall(
      (
        object_relation(location, Item, PlayerLocation),
        object_definition(item, Item, ItemName),
        create('img', ItemDom)
      ),
      (
        atomic_list_concat(['./img/', Item, '.png'], '', ItemImage),
        atomic_list_concat(['Take the <u>', ItemName, '</u>.'], '', ItemTitle),
        set_attr(ItemDom, 'alt', ItemName),
        set_attr(ItemDom, 'class', 'item_img mx-2 mb-2'),
        set_attr(ItemDom, 'data-bs-html', 'true'),
        set_attr(ItemDom, 'data-bs-toggle', 'tooltip'),
        set_attr(ItemDom, 'data-bs-placement', 'bottom'),
        set_attr(ItemDom, 'role', 'button'),
        set_attr(ItemDom, 'src', ItemImage),
        set_attr(ItemDom, 'title', ItemTitle),
        bind(ItemDom, click, _, take(Item)),
        append_child(RoomItemListDom, ItemDom),
        apply('hideActions', [], _)
      )
    ),
    % Update inventory items
    get_by_id('inventory_items', InventoryItemListDom),
    set_html(InventoryItemListDom, ''),
    forall(
      (
        object_relation(inventory, Item, player),
        object_definition(item, Item, ItemName),
        create('img', ItemDom)
      ),
      (
        atomic_list_concat(['./img/', Item, '.png'], '', ItemImage),
        atomic_list_concat(['Drop the <u>', ItemName, '</u>.'], '', ItemTitle),
        set_attr(ItemDom, 'alt', ItemName),
        set_attr(ItemDom, 'class', 'item_img mx-2'),
        set_attr(ItemDom, 'data-bs-html', 'true'),
        set_attr(ItemDom, 'data-bs-toggle', 'tooltip'),
        set_attr(ItemDom, 'data-bs-placement', 'top'),
        set_attr(ItemDom, 'role', 'button'),
        set_attr(ItemDom, 'src', ItemImage),
        set_attr(ItemDom, 'title', ItemTitle),
        bind(ItemDom, click, _, drop(Item)),
        append_child(InventoryItemListDom, ItemDom),
        apply('hideActions', [], _)
      )
    ),
    % Call the JS function
    apply('updateUI', [], _).