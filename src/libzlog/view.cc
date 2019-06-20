#include "view.h"
#include <iostream>
#include "include/zlog/options.h"
#include "libzlog/zlog_generated.h"

namespace zlog {

std::string View::create_initial(const Options& options)
{
  flatbuffers::FlatBufferBuilder fbb;

  // - next_stripe_id = 0
  // - no stripes
  // TODO: if (options.create_initial_view_stripes) ...
  const auto object_map = zlog::fbs::CreateObjectMapDirect(fbb, 0, nullptr);

  auto builder = zlog::fbs::ViewBuilder(fbb);
  builder.add_object_map(object_map);
  builder.add_min_valid_position(0);

  auto view = builder.Finish();
  fbb.Finish(view);

  return std::string(
      reinterpret_cast<const char*>(fbb.GetBufferPointer()), fbb.GetSize());
}

std::string View::encode() const
{
  flatbuffers::FlatBufferBuilder fbb;

  const auto encoded_object_map = object_map.encode(fbb);

  flatbuffers::Offset<zlog::fbs::Sequencer> seq =
    seq_config ? seq_config->encode(fbb) : 0;

  auto builder = zlog::fbs::ViewBuilder(fbb);
  builder.add_object_map(encoded_object_map);
  builder.add_sequencer(seq);
  builder.add_min_valid_position(min_valid_position);

  auto view = builder.Finish();
  fbb.Finish(view);

  return std::string(
      reinterpret_cast<const char*>(fbb.GetBufferPointer()), fbb.GetSize());
}

View::View(const std::string& prefix, const zlog::fbs::View *view) :
  object_map(ObjectMap::decode(prefix, view->object_map())),
  min_valid_position(view->min_valid_position()),
  seq_config(SequencerConfig::decode(view->sequencer()))
{}

boost::optional<View> View::expand_mapping(const std::string& prefix,
    const uint64_t position, const Options& options) const
{
  const auto new_object_map = object_map.expand_mapping(prefix, position,
      options);
  if (new_object_map) {
    return View(*new_object_map, min_valid_position, seq_config);
  }
  return boost::none;
}


boost::optional<View> View::advance_min_valid_position(uint64_t position) const
{
  if (position <= min_valid_position) {
    return boost::none;
  }
  return View(object_map, position, seq_config);
}

View View::set_sequencer_config(SequencerConfig seq_config) const
{
  return View(object_map, min_valid_position, seq_config);
}

}
