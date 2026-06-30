import "@hotwired/turbo-rails"

const bindAssistantComposer = () => {
  document.querySelectorAll("[data-assistant-form]").forEach((form) => {
    if (form.dataset.assistantBound === "true") return
    form.dataset.assistantBound = "true"

    const input = form.querySelector("[data-assistant-form-target='input']")
    const submit = form.querySelector("[data-assistant-form-target='submit']")

    input?.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" || event.shiftKey) return
      if (event.isComposing || input.readOnly || submit?.disabled) return
      if (!input.value.trim()) return

      event.preventDefault()
      form.requestSubmit()
    })

    form.addEventListener("turbo:submit-start", () => {
      if (submit) {
        submit.dataset.originalLabel = submit.value
        submit.value = "Sending..."
        submit.disabled = true
      }

      if (input) input.readOnly = true
    })

    form.addEventListener("turbo:submit-end", (event) => {
      if (submit) {
        submit.value = submit.dataset.originalLabel || "Send"
        submit.disabled = false
      }

      if (input) {
        input.readOnly = false
        if (event.detail.success) input.value = ""
        input.focus()
      }
    })
  })

  const chatBody = document.getElementById("assistant-chat-body")
  if (chatBody) chatBody.scrollTop = chatBody.scrollHeight
}

const bindModelPicker = () => {
  document.querySelectorAll("[data-controller='model-picker']").forEach((form) => {
    if (form.dataset.modelPickerBound === "true") return
    form.dataset.modelPickerBound = "true"

    const assistantCatalog = JSON.parse(form.dataset.assistantCatalog || "{}")
    const embeddingCatalog = JSON.parse(form.dataset.embeddingCatalog || "{}")

    const assistantProvider = form.querySelector("[data-model-picker-target='assistantProvider']")
    const assistantPreset = form.querySelector("[data-model-picker-target='assistantPreset']")
    const assistantInput = form.querySelector("[data-model-picker-target='assistantInput']")
    const embeddingProvider = form.querySelector("[data-model-picker-target='embeddingProvider']")
    const embeddingPreset = form.querySelector("[data-model-picker-target='embeddingPreset']")
    const embeddingInput = form.querySelector("[data-model-picker-target='embeddingInput']")
    const connectionCard = form.querySelector("[data-model-picker-target='connectionCard']")
    const assistantStatus = form.querySelector("[data-model-picker-target='assistantStatus']")
    const embeddingStatus = form.querySelector("[data-model-picker-target='embeddingStatus']")
    const embeddingCapability = form.querySelector("[data-model-picker-target='embeddingCapability']")
    const sidebarEmbeddingStatus = form.querySelector("[data-model-picker-target='sidebarEmbeddingStatus']") || document.querySelector("[data-model-picker-target='sidebarEmbeddingStatus']")
    const embeddingBaselineNotice = form.querySelector("[data-model-picker-target='anthropicNotice']") || document.querySelector("[data-model-picker-target='anthropicNotice']")

    const providerRequirements = {
      local: "No external credential required",
      openai: "Current embedding storage supports 1024-dimension local or Ollama models only",
      anthropic: "Requires ANTHROPIC_API_KEY",
      ollama: "Requires reachable Ollama base URL"
    }

    const providerReadiness = (provider) => {
      if (provider === "local") return "Ready"
      if (provider === "ollama") return "Depends on local Ollama runtime"
      if (provider === "openai") return "Not supported on current embedding storage"
      return "Depends on environment credential"
    }

    const rebuildOptions = (select, models, currentValue) => {
      if (!select) return

      select.innerHTML = ""

      const customOption = document.createElement("option")
      customOption.value = ""
      customOption.textContent = "Custom model"
      select.appendChild(customOption)

      models.forEach((model) => {
        const option = document.createElement("option")
        option.value = model
        option.textContent = model
        if (model === currentValue) option.selected = true
        select.appendChild(option)
      })

      if (!models.includes(currentValue)) customOption.selected = true
    }

    const syncPresetToInput = (preset, input) => {
      if (preset && input && preset.value) input.value = preset.value
    }

    const refreshAssistantModels = () => {
      const models = assistantCatalog[assistantProvider.value] || []
      rebuildOptions(assistantPreset, models, assistantInput.value)
      if (!assistantInput.value && models[0]) assistantInput.value = models[0]
    }

    const refreshEmbeddingModels = () => {
      const models = embeddingCatalog[embeddingProvider.value] || []
      rebuildOptions(embeddingPreset, models, embeddingInput.value)
      if (!embeddingInput.value && models[0]) embeddingInput.value = models[0]
    }

    const refreshVisibility = () => {
      const usesOllama = assistantProvider.value === "ollama" || embeddingProvider.value === "ollama"
      if (connectionCard) connectionCard.classList.toggle("is-hidden", !usesOllama)

      if (assistantStatus) {
        assistantStatus.textContent = `${providerReadiness(assistantProvider.value)} · ${providerRequirements[assistantProvider.value]}`
      }

      const embeddingSupported = ["local", "ollama"].includes(embeddingProvider.value)
      if (embeddingCapability) {
        embeddingCapability.textContent = embeddingSupported
          ? `Embedding retrieval is supported for ${embeddingProvider.value.charAt(0).toUpperCase() + embeddingProvider.value.slice(1)} on the current 1024-dimension storage baseline.`
          : `${embeddingProvider.value.charAt(0).toUpperCase() + embeddingProvider.value.slice(1)} embeddings are disabled on the current storage baseline.`
      }

      if (embeddingStatus) {
        embeddingStatus.textContent = `${providerReadiness(embeddingProvider.value)} · ${providerRequirements[embeddingProvider.value]}`
      }

      if (sidebarEmbeddingStatus) {
        sidebarEmbeddingStatus.textContent = `${embeddingProvider.value.charAt(0).toUpperCase() + embeddingProvider.value.slice(1)} · ${embeddingProvider.value === "local" ? "ready to use" : embeddingProvider.value === "ollama" ? "depends on local runtime" : "unsupported on current storage"}`
      }

      if (embeddingBaselineNotice) embeddingBaselineNotice.classList.remove("is-hidden")
    }

    assistantProvider?.addEventListener("change", () => {
      assistantInput.value = ""
      refreshAssistantModels()
      refreshVisibility()
    })

    embeddingProvider?.addEventListener("change", () => {
      embeddingInput.value = ""
      refreshEmbeddingModels()
      refreshVisibility()
    })

    assistantPreset?.addEventListener("change", () => syncPresetToInput(assistantPreset, assistantInput))
    embeddingPreset?.addEventListener("change", () => syncPresetToInput(embeddingPreset, embeddingInput))

    assistantInput?.addEventListener("input", () => rebuildOptions(
      assistantPreset,
      assistantCatalog[assistantProvider.value] || [],
      assistantInput.value
    ))

    embeddingInput?.addEventListener("input", () => rebuildOptions(
      embeddingPreset,
      embeddingCatalog[embeddingProvider.value] || [],
      embeddingInput.value
    ))

    refreshAssistantModels()
    refreshEmbeddingModels()
    refreshVisibility()
  })
}

const bindImpactForm = () => {
  document.querySelectorAll("[data-impact-form]").forEach((form) => {
    if (form.dataset.impactBound === "true") return
    form.dataset.impactBound = "true"

    const input = form.querySelector("[data-impact-form-target='input']")
    const submit = form.querySelector("[data-impact-form-target='submit']")

    form.addEventListener("turbo:submit-start", () => {
      if (submit) {
        submit.dataset.originalLabel = submit.value
        submit.value = "Analyzing..."
        submit.disabled = true
      }

      if (input) input.readOnly = true
    })

    form.addEventListener("turbo:submit-end", () => {
      if (submit) {
        submit.value = submit.dataset.originalLabel || "Analyze Impact"
        submit.disabled = false
      }

      if (input) {
        input.readOnly = false
        input.focus()
      }
    })
  })
}

const bindModals = () => {
  document.querySelectorAll("[data-modal-open]").forEach((trigger) => {
    if (trigger.dataset.modalBound === "true") return
    trigger.dataset.modalBound = "true"

    trigger.addEventListener("click", () => {
      const modal = document.getElementById(trigger.dataset.modalOpen)
      if (!modal) return

      modal.classList.remove("is-hidden")
      document.body.classList.add("modal-open")
    })
  })

  document.querySelectorAll("[data-modal-close]").forEach((trigger) => {
    if (trigger.dataset.modalCloseBound === "true") return
    trigger.dataset.modalCloseBound = "true"

    trigger.addEventListener("click", () => {
      const modal = document.getElementById(trigger.dataset.modalClose)
      if (!modal) return

      modal.classList.add("is-hidden")
      document.body.classList.remove("modal-open")
    })
  })

  document.querySelectorAll("[data-modal]").forEach((modal) => {
    if (modal.dataset.modalOverlayBound === "true") return
    modal.dataset.modalOverlayBound = "true"

    modal.addEventListener("click", (event) => {
      if (event.target !== modal) return

      modal.classList.add("is-hidden")
      document.body.classList.remove("modal-open")
    })
  })

  if (!document.body.dataset.modalEscapeBound) {
    document.body.dataset.modalEscapeBound = "true"

    document.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return

      document.querySelectorAll("[data-modal]:not(.is-hidden)").forEach((modal) => {
        modal.classList.add("is-hidden")
      })
      document.body.classList.remove("modal-open")
    })
  }

  if (!document.querySelector("[data-modal]:not(.is-hidden)")) {
    document.body.classList.remove("modal-open")
  }
}

const bindAppUi = () => {
  bindAssistantComposer()
  bindImpactForm()
  bindModelPicker()
  bindModals()
}

document.addEventListener("turbo:load", bindAppUi)
document.addEventListener("turbo:render", bindAppUi)
document.addEventListener("turbo:frame-load", bindAppUi)
document.addEventListener("turbo:before-stream-render", () => {
  setTimeout(() => {
    bindAppUi()

    const chatBody = document.getElementById("assistant-chat-body")
    if (chatBody) chatBody.scrollTop = chatBody.scrollHeight
  }, 0)
})
