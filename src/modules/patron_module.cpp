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

#include "modules/patron_module.h"

#include <string>

#include "entity/entity_manager.h"
#include "breadboard/event_system.h"
#include "breadboard/base_node.h"
#include "fplbase/utilities.h"
#include "rail_denizen.h"

namespace fpl {
namespace fpl_project {

// Constant indicating a lap duration (1.0f + some threshold).
// The threshold is for an edge case that the player feeds a patron for the next
// lap.
const float kLapDuration = 1.0f + 1.0f / 20.0f;

// Returns if the given entity is a patron, and standing upright.
class PatronUprightNode : public breadboard::BaseNode {
 public:
  PatronUprightNode(PatronComponent* patron_component)
      : patron_component_(patron_component) {}

  static void OnRegister(breadboard::NodeSignature* node_sig) {
    node_sig->AddInput<entity::EntityRef>();
    node_sig->AddOutput<bool>();
  }

  virtual void Initialize(breadboard::NodeArguments* args) { Run(args); }

  virtual void Execute(breadboard::NodeArguments* args) { Run(args); }

 private:
  void Run(breadboard::NodeArguments* args) {
    auto entity = args->GetInput<entity::EntityRef>(0);
    if (entity != nullptr && entity->IsValid()) {
      PatronData* data = patron_component_->GetComponentData(*entity);
      args->SetOutput(0, data != nullptr && data->state == kPatronStateUpright);
    }
  }

  PatronComponent* patron_component_;
};

// Check DeliciousCycle condition.
class CheckDeliciousCycleNode : public breadboard::BaseNode {
 public:
  CheckDeliciousCycleNode(PatronComponent* patron_component)
      : patron_component_(patron_component) {}

  static void OnRegister(breadboard::NodeSignature* node_sig) {
    node_sig->AddInput<void>();
    node_sig->AddInput<entity::EntityRef>();
    node_sig->AddOutput<int32_t>();
  }

  virtual void Execute(breadboard::NodeArguments* args) {
    auto raft = args->GetInput<entity::EntityRef>(1);
    auto current_lap =
        patron_component_->Data<RailDenizenData>(*raft)->lap - kLapDuration;

    auto num_patrons = 0;
    auto patrons_fed = 0;

    for (auto iter = patron_component_->begin();
         iter != patron_component_->end(); ++iter) {
      entity::EntityRef patron = iter->entity;
      PatronData* patron_data = patron_component_->GetComponentData(patron);

      // Check if patrons are fed in the current lap.
      // Also count the first hippo since it doesn't appear for 2nd/3rd lap.
      if (patron_data->last_lap_fed >= current_lap ||
          patron_data->last_lap_fed == 0.0f) {
        patrons_fed++;
      }
      num_patrons++;
    }
    LogInfo("Total: %d patrons, Fed:%d patrons", num_patrons, patrons_fed);

    auto ret = 1;
    if (num_patrons > patrons_fed) {
      ret = 0;
    }

    args->SetOutput(0, ret);
  }

 private:
  PatronComponent* patron_component_;
};

void InitializePatronModule(breadboard::EventSystem* event_system,
                            PatronComponent* patron_component) {
  breadboard::Module* module = event_system->AddModule("patron");
  auto patron_upright_ctor = [patron_component]() {
    return new PatronUprightNode(patron_component);
  };
  auto check_delicious_cycle_ctor = [patron_component]() {
    return new CheckDeliciousCycleNode(patron_component);
  };
  module->RegisterNode<PatronUprightNode>("patron_upright",
                                          patron_upright_ctor);
  module->RegisterNode<CheckDeliciousCycleNode>("check_delicious_cycle",
                                                check_delicious_cycle_ctor);
}

}  // fpl_project
}  // fpl