#include "bridge.hpp"

bridge_writer::bridge_writer(void (^block)(const void*, size_t)) : write_block(block) {}

bridge_writer::~bridge_writer() {
    if (write_block) {
        //Block_release(write_block);
    }
}

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
                                void (^block)(const void*, size_t))
{
    bridge_writer writer(block);
    node.print(writer, indent, flags, encoding, depth);
}

void xml_document_save_with_block (
                                const pugi::xml_document& node,
                                const pugi::char_t* indent,
                                unsigned int flags,
                                pugi::xml_encoding encoding,
                                void (^block)(const void*, size_t))
{
    bridge_writer writer(block);
    node.save(writer, indent, flags, encoding);
}

// This is dumb, but it's needed due to a limitation of Swift's C++ interop
pugi::xml_node xml_document_as_node(const pugi::xml_document& document) {
    return document;
}


bridge_walker::bridge_walker(bool (^block)(const pugi::xml_node& node, int depth)) : foreach_block(block) {}

bridge_walker::~bridge_walker() {
    if (foreach_block) {
        //Block_release(foreach_block);
    }
}

bool bridge_walker::for_each(pugi::xml_node& node) {
    if (foreach_block) {
        return foreach_block(node, depth());
    } else {
        return false;
    }
}

bool xml_node_walk_block(pugi::xml_node& node, bool (^block)(const pugi::xml_node& node, int depth)) {
    bridge_walker walker(block);
    return node.traverse(walker);
}
