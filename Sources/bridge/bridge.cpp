#include "bridge.hpp"

bridge_writer::bridge_writer(void (^block)(const void*, size_t)) : write_block(block) {}
bridge_writer::~bridge_writer() {}

void bridge_writer::write(const void* data, size_t size) {
    if (write_block) {
        write_block(data, size);
    }
}

// A wrapper function to call xml_node::print with a Clang block
void xml_node_print_with_block (
                                const pugi::xml_node& node,
                                const pugi::char_t* indent,
                                unsigned int flags,
                                pugi::xml_encoding encoding,
                                unsigned int depth,
                                void (^block)(const void*, size_t)
){
    bridge_writer writer(block);
    node.print(writer, indent, flags, encoding, depth);
}

void xml_document_save_with_block (
                                const pugi::xml_document& node,
                                const pugi::char_t* indent,
                                unsigned int flags,
                                pugi::xml_encoding encoding,
                                void (^block)(const void*, size_t)
){
    bridge_writer writer(block);
    node.save(writer, indent, flags, encoding);
}

// This is dumb, but it's needed due to a limitation of Swift's C++ interop
pugi::xml_node xml_document_as_node(const pugi::xml_document& document) {
    return document;
}
