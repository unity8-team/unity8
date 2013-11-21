#
# Thrift 0.8.0 prebuilt shared C++ librariy
#

__WAS_PATH := $(LOCAL_PATH)
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := thrift_prebuilt_shared
LOCAL_SRC_FILES := ../lib/$(TARGET_ARCH_ABI)/libthrift.so
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/..
LOCAL_EXPORT_CPPFLAGS := -DHAVE_CONFIG_H -D__GLIBC__

include $(PREBUILT_SHARED_LIBRARY)

LOCAL_PATH := $(__WAS_PATH)
