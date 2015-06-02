// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef FPL_EVENTS_ENTITY_EVENT_H_
#define FPL_EVENTS_ENTITY_EVENT_H_

#include "entity/entity_manager.h"

namespace fpl {
namespace fpl_project {

// This is not an event payload for any specific entity. This is meant to be
// inherited by anything that wants to send a specific entity an event.
struct EntityEvent {
  EntityEvent(entity::EntityRef& target_) : target(target_) {}
  entity::EntityRef target;
};

}  // fpl_project
}  // fpl

#endif  // FPL_EVENTS_ENTITY_EVENT_H_
